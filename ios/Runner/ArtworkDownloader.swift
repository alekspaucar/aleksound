import Foundation
import ImageIO

/// Thumbnail lookup only: never resolves or downloads an audio source.
enum ArtworkDownloader {
  static let byteLimit = 3 * 1024 * 1024

  static func candidates(videoID: String, supplied: String?) -> [URL] {
    guard videoID.range(of: "^[A-Za-z0-9_-]{11}$", options: .regularExpression) != nil else { return [] }
    var names: [String] = []
    if let raw = supplied, let url = URL(string: raw), url.scheme == "https",
       ["i.ytimg.com", "img.youtube.com"].contains(url.host ?? ""),
       url.pathComponents.count == 4, url.pathComponents[1] == "vi",
       url.pathComponents[2] == videoID,
       ["maxresdefault.jpg", "sddefault.jpg", "hqdefault.jpg", "mqdefault.jpg"].contains(url.lastPathComponent) {
      names.append(url.lastPathComponent)
    }
    // Both thumbnail hosts refer to the same video. Canonicalize search covers
    // too, and retry a standard size if a larger thumbnail does not exist.
    for name in ["hqdefault.jpg", "mqdefault.jpg"] where !names.contains(name) { names.append(name) }
    return names.compactMap { URL(string: "https://i.ytimg.com/vi/\(videoID)/\($0)") }
  }

  static func validImage(_ data: Data) -> Bool {
    guard !data.isEmpty, data.count <= byteLimit,
          let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int,
          width <= 4096, height <= 4096,
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return false }
    // YouTube's unavailable-thumbnail placeholder is only 120 × 90.
    return image.width >= 200 && image.height >= 100
  }

  static func fetch(videoID: String, supplied: String?, session: URLSession = .shared) async -> Data? {
    for url in candidates(videoID: videoID, supplied: supplied) {
      var request = URLRequest(url: url)
      request.timeoutInterval = 8
      do {
        // Download to a temporary file so an oversized response is not loaded
        // into memory. The local result is always removed after inspection.
        let (temporary, response) = try await session.download(for: request)
        defer { try? FileManager.default.removeItem(at: temporary) }
        guard let response = response as? HTTPURLResponse, response.statusCode == 200,
              let finalURL = response.url, finalURL.scheme == "https",
              finalURL.host == "i.ytimg.com", finalURL.path == url.path,
              let size = (try FileManager.default.attributesOfItem(atPath: temporary.path)[.size] as? NSNumber)?.intValue,
              size > 0, size <= byteLimit else { continue }
        let data = try Data(contentsOf: temporary)
        if validImage(data) { return data }
      } catch { /* A cover failure must never invalidate a verified audio file. */ }
    }
    return nil
  }
}
