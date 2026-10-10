import Flutter
import UIKit
import AVFoundation
import MediaPlayer
import JavaScriptCore

/// Owns iPhone files, background transfers and system media commands.
/// File names are generated here; paths/temporary signed URLs never enter backups.
final class NativeMusicPlugin: NSObject, URLSessionDownloadDelegate {
  private let channel: FlutterMethodChannel
  private let root: URL
  private var records: [[String: Any]] = []
  private var jobs: [String: [String: Any]] = [:]
  private var tasks: [String: URLSessionDownloadTask] = [:]
  private var completion: (() -> Void)?
  private var validations = 0
  private var libraryRepair: Task<Void, Error>?
  private var artworkRepair: Task<Void, Never>?
  private var artworkAttempts: [String: Date] = [:]
  private var artworkKey = ""
  private var cachedArtwork: MPMediaItemArtwork?
  private let scriptQueue = DispatchQueue(label: "aleksound.player.script")
  private var scriptContext: JSContext?
  private var previewRoot: URL {
    FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("AleksoundPreview", isDirectory: true)
  }
  private let previewSession: URLSession = {
    let c = URLSessionConfiguration.ephemeral
    c.timeoutIntervalForRequest = 30
    c.timeoutIntervalForResource = 180
    return URLSession(configuration: c)
  }()
  private lazy var session: URLSession = {
    let c = URLSessionConfiguration.background(withIdentifier: "aleksound.audio.downloads")
    c.sessionSendsLaunchEvents = true
    c.isDiscretionary = false
    c.timeoutIntervalForRequest = 60
    c.timeoutIntervalForResource = 3600
    return URLSession(configuration: c, delegate: self, delegateQueue: .main)
  }()

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "aleksound/native_music", binaryMessenger: messenger)
    root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Aleksound", isDirectory: true)
    super.init()
    do {
      try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
      if let data = try? Data(contentsOf: root.appendingPathComponent("library.json")),
         let decoded = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] { records = decoded }
    } catch { /* A storage failure is delivered by the next library/download request. */ }
    try? FileManager.default.createDirectory(at: previewRoot, withIntermediateDirectories: true)
    // Only our UUID-named listening cache is disposable after a new process.
    // A cache failure must never prevent loading the persistent library.
    for file in (try? FileManager.default.contentsOfDirectory(at: previewRoot, includingPropertiesForKeys: nil)) ?? [] {
      if isPreviewName(file.lastPathComponent) { try? FileManager.default.removeItem(at: file) }
    }
    jobs = UserDefaults.standard.dictionary(forKey: "aleksound.download.jobs") as? [String: [String: Any]] ?? [:]
    channel.setMethodCallHandler { [weak self] call, reply in self?.handle(call, reply: reply) }
    installCommands()
    session.getAllTasks { [weak self] pending in
      DispatchQueue.main.async {
        guard let self = self else { return }
        for task in pending {
          guard let task = task as? URLSessionDownloadTask, let id = self.identity(task),
                self.matches(task) else { task.cancel(); continue }
          self.tasks[id] = task
        }
        for (id, job) in self.jobs where self.tasks[id] == nil && job["status"] as? String != "failed" {
          self.fail(id, message: "La descarga se interrumpió. Pulsa reintentar.")
        }
        self.emit()
      }
    }
  }

  func handleBackgroundEvents(_ handler: @escaping () -> Void) { completion = handler; _ = session }

  private func handle(_ call: FlutterMethodCall, reply: @escaping FlutterResult) {
    do {
      switch call.method {
      case "mediaState":
        let info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        reply(["title": info[MPMediaItemPropertyTitle] ?? "", "rate": info[MPNowPlayingInfoPropertyPlaybackRate] ?? 0,
          "duration": info[MPMediaItemPropertyPlaybackDuration] ?? 0,
          "audioCategory": AVAudioSession.sharedInstance().category.rawValue,
          "backgroundAudio": (Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String])?.contains("audio") == true,
          "commandsEnabled": MPRemoteCommandCenter.shared().playCommand.isEnabled])
      case "initializePlayerScript", "evaluatePlayerScript":
        guard let code = call.arguments as? String, code.utf8.count <= 12 * 1024 * 1024 else { throw MusicError("El reproductor no pudo preparar esta canción.") }
        scriptQueue.async { [weak self] in
          guard let self = self else { return }
          if call.method == "initializePlayerScript" { self.scriptContext = JSContext() }
          guard let context = self.scriptContext else {
            DispatchQueue.main.async { reply(FlutterError(code: "script", message: "Reproductor sin inicializar.", details: nil)) }; return
          }
          context.exception = nil
          let result = context.evaluateScript(code)
          let failed = context.exception != nil
          let value = call.method == "initializePlayerScript" ? nil : result?.toString()
          DispatchQueue.main.async {
            if failed { reply(FlutterError(code: "script", message: "No se pudo procesar el audio de esta versión.", details: nil)) }
            else { reply(value) }
          }
        }
      case "library":
        Task { @MainActor in
          do {
            try await self.repairLibrary()
            // Return local audio immediately, including when offline. Missing
            // artwork is recovered independently and published when ready.
            self.startArtworkRepair()
            reply(try self.snapshot())
          }
          catch {
            reply(FlutterError(code: "audio_repair", message: "No se pudo preparar la biblioteca. Tus archivos se conservan; vuelve a abrir Aleksound para reintentar.", details: nil))
          }
        }
      case "preparePlayback":
        guard let data = call.arguments as? [String: Any] else { throw MusicError("Canción inválida.") }
        Task { @MainActor in
          do { reply(try await self.preparePlayback(data)) }
          catch {
            reply(FlutterError(code: "audio_preview", message: (error as? MusicError)?.message ?? "No se pudo preparar el audio. Comprueba internet y el espacio disponible; después reintenta.", details: nil))
          }
        }
      case "releasePlayback":
        if let raw = call.arguments as? String, let url = URL(string: raw), url.isFileURL,
           url.deletingLastPathComponent().standardizedFileURL == previewRoot.standardizedFileURL,
           isPreviewName(url.lastPathComponent) { try? FileManager.default.removeItem(at: url) }
        reply(nil)
      case "download":
        guard let data = call.arguments as? [String: Any], let id = data["id"] as? String,
              let video = data["videoId"] as? String,
              video.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil,
              id == "youtube:" + video,
              let raw = data["url"] as? String, let url = URL(string: raw),
              url.scheme == "https", let host = url.host, host.hasSuffix(".googlevideo.com"),
              let bytes = data["bytes"] as? Int, bytes > 1024, bytes <= 300 * 1024 * 1024
        else { throw MusicError("No se puede descargar esta fuente de audio.") }
        if tasks[id] != nil { reply(nil); return }
        let capacity = try root.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
        if let available = capacity, available < Int64(bytes * 2 + 50 * 1024 * 1024) {
          throw MusicError("No hay suficiente espacio. Libera almacenamiento y reintenta.")
        }
        var job = data
        job.removeValue(forKey: "url")
        job.removeValue(forKey: "headers")
        let token = UUID().uuidString
        job["token"] = token; job["status"] = "downloading"; job["progress"] = 0.0
        var request = URLRequest(url: url)
        if let headers = data["headers"] as? [String: String] {
          for name in ["User-Agent", "Accept", "Range"] {
            if let value = headers[name], value.utf8.count < 1024 { request.setValue(value, forHTTPHeaderField: name) }
          }
        }
        let task = session.downloadTask(with: request)
        task.taskDescription = id + "|" + token
        jobs[id] = job; tasks[id] = task; persistJobs()
        task.resume(); emit(); reply(nil)
      case "cancel":
        if let id = call.arguments as? String { cancel(id) }
        reply(nil)
      case "delete":
        guard let id = call.arguments as? String else { throw MusicError("Canción inválida.") }
        cancel(id)
        let removed = records.filter { $0["id"] as? String == id }
        let previous = records
        records.removeAll { $0["id"] as? String == id }
        do { try persistRecords() } catch { records = previous; throw error }
        for record in removed {
          for key in ["audioFile", "artworkFile", "originalAudioFile"] {
            if let file = record[key] as? String, let url = safeFile(file) { try? FileManager.default.removeItem(at: url) }
          }
        }
        emit(); reply(nil)
      case "nowPlaying":
        if let data = call.arguments as? [String: Any] { updateNowPlaying(data) }
        reply(nil)
      default: reply(FlutterMethodNotImplemented)
      }
    } catch {
      reply(FlutterError(code: "music", message: (error as? MusicError)?.message ?? "No se pudo guardar el archivo en el iPhone. Comprueba el espacio disponible.", details: nil))
    }
  }

  private func safeFile(_ name: String) -> URL? {
    guard !name.isEmpty, name == (name as NSString).lastPathComponent, !name.contains("..") else { return nil }
    return root.appendingPathComponent(name)
  }
  private func isPreviewName(_ name: String) -> Bool {
    guard name.hasSuffix(".m4a"), name == (name as NSString).lastPathComponent else { return false }
    var stem = (name as NSString).deletingPathExtension
    if stem.hasSuffix(".source") { stem = String(stem.dropLast(7)) }
    return UUID(uuidString: stem) != nil
  }
  /// Online listening uses a transient, verified M4A, not a fragmented remote
  /// timeline. It never creates a downloaded record or touches library files.
  @MainActor
  private func preparePlayback(_ data: [String: Any]) async throws -> [String: Any] {
    guard let id = data["id"] as? String, let video = data["videoId"] as? String,
          video.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil,
          id == "youtube:" + video,
          let raw = data["url"] as? String, let url = URL(string: raw),
          url.scheme == "https", let host = url.host, host.hasSuffix(".googlevideo.com"),
          let bytes = data["bytes"] as? Int, bytes > 1024, bytes <= 300 * 1024 * 1024 else {
      throw MusicError("No se puede preparar esta fuente de audio.")
    }
    try FileManager.default.createDirectory(at: previewRoot, withIntermediateDirectories: true)
    let capacity = try previewRoot.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage
    if let available = capacity, available < Int64(bytes * 2 + 50 * 1024 * 1024) {
      throw MusicError("No hay suficiente espacio para preparar el audio.")
    }
    var request = URLRequest(url: url)
    if let headers = data["headers"] as? [String: String] {
      for name in ["User-Agent", "Accept", "Range"] {
        if let value = headers[name], value.utf8.count < 1024 { request.setValue(value, forHTTPHeaderField: name) }
      }
    }
    let token = UUID().uuidString
    let source = previewRoot.appendingPathComponent(token + ".source.m4a")
    let output = previewRoot.appendingPathComponent(token + ".m4a")
    defer { try? FileManager.default.removeItem(at: source) }
    do {
      let (location, response) = try await previewSession.download(for: request)
      guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        throw MusicError("YouTube rechazó el audio (HTTP \(status)). Pulsa reproducir otra vez para obtener una fuente nueva.")
      }
      let size = (try FileManager.default.attributesOfItem(atPath: location.path)[.size] as? NSNumber)?.intValue ?? 0
      guard size == bytes else { throw MusicError("El audio está incompleto. Reintenta con internet.") }
      try FileManager.default.moveItem(at: location, to: source)
      let prepared = try await AudioFileFinalizer.prepare(source: source, destination: output)
      return ["audioUri": output.absoluteString, "duration": prepared.duration]
    } catch {
      try? FileManager.default.removeItem(at: output)
      throw error
    }
  }
  private func snapshot() throws -> [String: Any] {
    var valid: [[String: Any]] = []
    for record in records {
      guard let name = record["audioFile"] as? String, let url = safeFile(name),
            let bytes = record["bytes"] as? Int,
            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
            (attrs[.size] as? NSNumber)?.intValue == bytes, bytes > 1024 else { continue }
      var r = record
      r["audioUri"] = url.absoluteString
      if let art = record["artworkFile"] as? String, let artURL = safeFile(art), FileManager.default.fileExists(atPath: artURL.path) {
        r["artworkUri"] = artURL.absoluteString
      }
      valid.append(r)
    }
    return ["records": valid, "jobs": Array(jobs.values)]
  }
  /// Migrate old downloads locally, one file at a time, before exposing them to
  /// AVPlayer. Keep each original as a recovery copy; replace only the index.
  /// Concurrent refreshes share this task and cannot repackage the same file.
  @MainActor
  private func repairLibrary() async throws {
    if let repair = libraryRepair { try await repair.value; return }
    let repair = Task { @MainActor in
      let pending = self.records.filter { ($0["timingVersion"] as? Int ?? 0) < AudioFileFinalizer.timingVersion }
      for record in pending {
        guard let id = record["id"] as? String,
              let oldName = record["audioFile"] as? String, let original = self.safeFile(oldName),
              let expected = record["bytes"] as? Int,
              let attrs = try? FileManager.default.attributesOfItem(atPath: original.path),
              (attrs[.size] as? NSNumber)?.intValue == expected, expected > 1024 else { continue }
        let name = UUID().uuidString + ".m4a"
        let output = self.root.appendingPathComponent(name)
        let prepared = try await AudioFileFinalizer.prepare(source: original, destination: output)
        // A deletion/new download during the await wins over this migration.
        guard let index = self.records.firstIndex(where: {
          $0["id"] as? String == id && $0["audioFile"] as? String == oldName
        }) else { try? FileManager.default.removeItem(at: output); continue }
        let previous = self.records[index]
        self.records[index]["audioFile"] = name
        self.records[index]["originalAudioFile"] = oldName
        self.records[index]["bytes"] = prepared.bytes
        self.records[index]["duration"] = prepared.duration
        self.records[index]["timingVersion"] = AudioFileFinalizer.timingVersion
        do { try self.persistRecords() }
        catch {
          self.records[index] = previous
          try? FileManager.default.removeItem(at: output)
          throw error
        }
      }
    }
    libraryRepair = repair
    defer { libraryRepair = nil }
    try await repair.value
  }
  private func persistRecords() throws {
    let data = try JSONSerialization.data(withJSONObject: records)
    try data.write(to: root.appendingPathComponent("library.json"), options: .atomic)
  }

  private func hasArtwork(_ record: [String: Any]) -> Bool {
    guard let name = record["artworkFile"] as? String, let url = safeFile(name),
          let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size]) as? NSNumber else { return false }
    return size.intValue > 0
  }

  /// Retry only the image, never the audio. Coalesce concurrent refreshes and
  /// limit failed attempts to one per minute, or retry after reopening the app.
  @MainActor
  private func startArtworkRepair() {
    guard artworkRepair == nil else { return }
    let pending = records.filter { record in
      guard !hasArtwork(record), let id = record["id"] as? String,
            let video = record["videoId"] as? String, id == "youtube:" + video,
            let audio = record["audioFile"] as? String, let url = safeFile(audio),
            FileManager.default.fileExists(atPath: url.path) else { return false }
      let key = id + "|" + audio
      return Date().timeIntervalSince(artworkAttempts[key] ?? .distantPast) >= 60
    }
    guard !pending.isEmpty else { return }
    artworkRepair = Task { @MainActor in
      defer { self.artworkRepair = nil }
      for record in pending {
        guard let id = record["id"] as? String, let video = record["videoId"] as? String,
              let audio = record["audioFile"] as? String else { continue }
        self.artworkAttempts[id + "|" + audio] = Date()
        guard let data = await ArtworkDownloader.fetch(videoID: video, supplied: record["artworkUrl"] as? String),
              let index = self.records.firstIndex(where: { $0["id"] as? String == id && $0["audioFile"] as? String == audio }),
              !self.hasArtwork(self.records[index]) else { continue }
        // A deletion/replacement during the request wins. Commit only the cover
        // to the same record; all audio filenames, bytes and metadata survive.
        let name = UUID().uuidString + ".jpg", url = self.root.appendingPathComponent(name)
        let previous = self.records[index]
        do {
          try data.write(to: url, options: .atomic)
          self.records[index]["artworkFile"] = name
          try self.persistRecords()
          self.emit()
        } catch {
          self.records[index] = previous
          try? FileManager.default.removeItem(at: url)
        }
      }
    }
  }
  private func persistJobs() { UserDefaults.standard.set(jobs, forKey: "aleksound.download.jobs") }
  private func emit() { channel.invokeMethod("event", arguments: ["kind": "downloads"]) }
  private func identity(_ task: URLSessionTask) -> String? { task.taskDescription?.components(separatedBy: "|").first }
  private func matches(_ task: URLSessionTask) -> Bool {
    guard let id = identity(task), let token = jobs[id]?["token"] as? String else { return false }
    return task.taskDescription == id + "|" + token
  }
  private func cancel(_ id: String) {
    tasks.removeValue(forKey: id)?.cancel()
    if let token = jobs[id]?["token"] as? String {
      try? FileManager.default.removeItem(at: root.appendingPathComponent(token + ".part"))
      try? FileManager.default.removeItem(at: root.appendingPathComponent(token + ".part.m4a"))
    }
    jobs.removeValue(forKey: id); persistJobs(); emit()
  }
  private func fail(_ id: String, message: String) {
    tasks.removeValue(forKey: id)
    if let token = jobs[id]?["token"] as? String {
      try? FileManager.default.removeItem(at: root.appendingPathComponent(token + ".part"))
      try? FileManager.default.removeItem(at: root.appendingPathComponent(token + ".part.m4a"))
    }
    jobs[id]?["status"] = "failed"; jobs[id]?["error"] = message
    persistJobs(); emit()
  }
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    guard matches(downloadTask), let id = identity(downloadTask) else { return }
    let expected = (jobs[id]?["bytes"] as? Int) ?? 0
    if totalBytesWritten > 300 * 1024 * 1024 || (expected > 0 && totalBytesWritten > Int64(expected)) {
      downloadTask.cancel(); fail(id, message: "El archivo no coincide con la canción. Reintenta."); return
    }
    let progress = expected > 0 ? min(0.99, Double(totalBytesWritten) / Double(expected)) : 0
    let old = jobs[id]?["progress"] as? Double ?? 0
    if progress - old >= 0.01 {
      jobs[id]?["progress"] = progress; emit()
    }
  }
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    guard matches(downloadTask), let id = identity(downloadTask), let job = jobs[id], let token = job["token"] as? String else { return }
    guard let response = downloadTask.response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
      let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
      fail(id, message: "YouTube rechazó la descarga (HTTP \(status)). Reintenta para obtener una fuente nueva."); return
    }
    // AVFoundation identifies a local resource by extension. A bare .part
    // fails with AVFoundationErrorDomain/-11828 even for a complete MP4 file.
    // This remains uncommitted until size, duration and playability pass.
    let temporary = root.appendingPathComponent(token + ".part.m4a")
    do { try FileManager.default.moveItem(at: location, to: temporary) }
    catch { fail(id, message: "No se pudo guardar el audio. Comprueba el espacio disponible."); return }
    jobs[id]?["status"] = "verifying"; persistJobs(); emit()
    validations += 1
    let background = UIApplication.shared.beginBackgroundTask(withName: "Aleksound valida audio")
    Task { @MainActor in
      defer {
        self.validations -= 1
        if background != .invalid { UIApplication.shared.endBackgroundTask(background) }
        self.finishEvents()
      }
      var committedAudio: URL?
      var validationStage = "size"
      do {
        let size = (try FileManager.default.attributesOfItem(atPath: temporary.path)[.size] as? NSNumber)?.intValue ?? 0
        guard size == job["bytes"] as? Int, size > 1024 else { throw MusicError("La descarga está incompleta. Reintenta.") }
        let name = token + ".m4a"
        let destination = root.appendingPathComponent(name)
        validationStage = "audio"
        let prepared = try await AudioFileFinalizer.prepare(source: temporary, destination: destination)
        committedAudio = destination
        try? FileManager.default.removeItem(at: temporary)
        guard self.matches(downloadTask) else { try? FileManager.default.removeItem(at: destination); return }
        var r: [String: Any] = ["id": id, "videoId": job["videoId"] ?? "", "title": job["title"] ?? "Canción", "artist": job["artist"] ?? "", "audioFile": name, "bytes": prepared.bytes, "duration": prepared.duration, "timingVersion": AudioFileFinalizer.timingVersion]
        // A missing cover never blocks an otherwise valid offline song.
        if let video = job["videoId"] as? String,
           let data = await ArtworkDownloader.fetch(videoID: video, supplied: job["artworkUrl"] as? String) {
          let artName = token + ".jpg"
          if (try? data.write(to: root.appendingPathComponent(artName), options: .atomic)) != nil { r["artworkFile"] = artName }
        }
        self.artworkAttempts[id + "|" + name] = Date()
        guard self.matches(downloadTask) else {
          try? FileManager.default.removeItem(at: destination)
          if let name = r["artworkFile"] as? String { try? FileManager.default.removeItem(at: root.appendingPathComponent(name)) }
          return
        }
        let previous = records
        records.removeAll { $0["id"] as? String == id }; records.append(r)
        validationStage = "index"
        do { try persistRecords() } catch { records = previous; throw error }
        jobs.removeValue(forKey: id); tasks.removeValue(forKey: id); persistJobs(); emit()
      } catch {
        #if DEBUG
        let diagnostic = error as NSError
        if matches(downloadTask) {
          jobs[id]?["diagnostic"] = "\(validationStage): \(diagnostic.domain) / \(diagnostic.code)"
        }
        #endif
        try? FileManager.default.removeItem(at: temporary)
        if let url = committedAudio { try? FileManager.default.removeItem(at: url) }
        try? FileManager.default.removeItem(at: root.appendingPathComponent(token + ".jpg"))
        if matches(downloadTask) {
          let fallback = validationStage == "audio"
            ? "El iPhone no pudo validar el audio de esta versión. Reintenta."
            : "No se pudo finalizar la descarga. Comprueba el espacio y reintenta."
          fail(id, message: (error as? MusicError)?.message ?? fallback)
        }
      }
    }
  }
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let error = error, matches(task), let id = identity(task), jobs[id]?["status"] as? String != "failed" else { return }
    let message = (error as NSError).code == NSURLErrorNotConnectedToInternet
      ? "Sin conexión. La descarga se puede reintentar cuando vuelva internet."
      : "La descarga se interrumpió. Pulsa reintentar."
    fail(id, message: message)
  }
  func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) { finishEvents() }
  private func finishEvents() {
    if validations == 0, let handler = completion { completion = nil; handler() }
  }

  private func installCommands() {
    let c = MPRemoteCommandCenter.shared()
    for (command, action) in [(c.playCommand, "play"), (c.pauseCommand, "pause"), (c.nextTrackCommand, "next"), (c.previousTrackCommand, "previous"), (c.stopCommand, "stop")] {
      command.addTarget { [weak self] _ in
        guard let self = self else { return .commandFailed }
        self.channel.invokeMethod("event", arguments: ["kind": "remote", "action": action])
        return .success
      }
    }
    c.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent, let self = self else { return .commandFailed }
      self.channel.invokeMethod("event", arguments: ["kind": "remote", "action": "seek", "position": event.positionTime])
      return .success
    }
  }
  private func updateNowPlaying(_ data: [String: Any]) {
    guard let title = data["title"] as? String, !title.isEmpty else {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      let c = MPRemoteCommandCenter.shared()
      for command in [c.playCommand, c.pauseCommand, c.nextTrackCommand, c.previousTrackCommand, c.changePlaybackPositionCommand, c.stopCommand] { command.isEnabled = false }
      return
    }
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title, MPMediaItemPropertyArtist: data["artist"] ?? "",
      MPMediaItemPropertyPlaybackDuration: data["duration"] ?? 0,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: data["position"] ?? 0,
      MPNowPlayingInfoPropertyPlaybackRate: (data["playing"] as? Bool == true) ? 1.0 : 0.0,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
    ]
    let key = data["artworkUri"] as? String ?? ""
    if artworkKey != key {
      artworkKey = key; cachedArtwork = nil
      if let url = URL(string: key), url.isFileURL, let image = UIImage(contentsOfFile: url.path) {
        cachedArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
      }
    }
    if let artwork = cachedArtwork { info[MPMediaItemPropertyArtwork] = artwork }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    let enabled = data["enabled"] as? Bool ?? false
    let c = MPRemoteCommandCenter.shared()
    for command in [c.playCommand, c.pauseCommand, c.nextTrackCommand, c.previousTrackCommand, c.changePlaybackPositionCommand, c.stopCommand] { command.isEnabled = enabled }
  }
}

private struct MusicError: Error { let message: String; init(_ message: String) { self.message = message } }
