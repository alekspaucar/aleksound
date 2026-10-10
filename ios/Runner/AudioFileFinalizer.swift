import Foundation
@preconcurrency import AVFoundation

/// Repackages AAC without re-encoding it. Fragmented MP4 may advertise both a
/// full movie duration and fragment durations; AVPlayer then adds an empty tail.
/// Audio packet frames, not that advertised timeline, define the real length.
enum AudioFileFinalizer {
  static let timingVersion = 1

  struct PreparedAudio {
    let bytes: Int
    let duration: Double
  }

  struct InvalidAudio: Error {}

  static func prepare(source: URL, destination: URL) async throws -> PreparedAudio {
    guard source != destination,
          !FileManager.default.fileExists(atPath: destination.path) else { throw InvalidAudio() }
    let input = try AVAudioFile(forReading: source)
    let rate = input.processingFormat.sampleRate
    let seconds = Double(input.length) / rate
    guard rate > 0, seconds.isFinite, seconds > 0 else { throw InvalidAudio() }
    let asset = AVURLAsset(url: source)
    guard try await asset.load(.isPlayable),
          let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough),
          exporter.supportedFileTypes.contains(.m4a) else { throw InvalidAudio() }
    exporter.timeRange = CMTimeRange(start: .zero,
      duration: CMTime(seconds: seconds, preferredTimescale: CMTimeScale(rate)))
    do {
      if #available(iOS 18.0, macOS 15.0, *) {
        try await exporter.export(to: destination, as: .m4a)
      } else {
        // Compatibility with the app's iOS 15 minimum.
        exporter.outputURL = destination
        exporter.outputFileType = .m4a
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
          exporter.exportAsynchronously {
            if exporter.status == .completed { continuation.resume() }
            else { continuation.resume(throwing: exporter.error ?? InvalidAudio()) }
          }
        }
      }
      let output = try AVAudioFile(forReading: destination)
      let outputRate = output.processingFormat.sampleRate
      let outputSeconds = Double(output.length) / outputRate
      let outputAsset = AVURLAsset(url: destination)
      let timeline = try await outputAsset.load(.duration).seconds
      let playable = try await outputAsset.load(.isPlayable)
      let size = (try FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? NSNumber)?.intValue ?? 0
      // Allow only AAC priming/rounding, never half a track or an empty tail.
      guard playable, size > 1024, size <= 300 * 1024 * 1024,
            outputRate == rate, abs(output.length - input.length) <= 4096,
            timeline.isFinite, abs(timeline - outputSeconds) <= 0.1,
            abs(outputSeconds - seconds) <= 0.1 else { throw InvalidAudio() }
      // Actually decode the tail; duration metadata alone is not validation.
      output.framePosition = max(0, output.length - AVAudioFramePosition(rate))
      guard let buffer = AVAudioPCMBuffer(pcmFormat: output.processingFormat,
        frameCapacity: AVAudioFrameCount(rate)) else { throw InvalidAudio() }
      try output.read(into: buffer)
      guard buffer.frameLength > 0 else { throw InvalidAudio() }
      return PreparedAudio(bytes: size, duration: timeline)
    } catch {
      // Only our new, uncommitted output is disposable. Never touch the source.
      try? FileManager.default.removeItem(at: destination)
      throw error
    }
  }
}
