import Foundation
import CoreGraphics
import ImageIO

@main
struct ArtworkRegression {
  static func jpeg(width: Int, height: Int) -> Data {
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.setFillColor(CGColor(red: 0.1, green: 0.3, blue: 0.5, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    precondition(CGImageDestinationFinalize(destination))
    return data as Data
  }

  static func main() {
    let id = "sDMxQF18yvA", standard = "https://i.ytimg.com/vi/\(id)/hqdefault.jpg"
    for host in ["img.youtube.com", "i.ytimg.com"] {
      let urls = ArtworkDownloader.candidates(videoID: id, supplied: "https://\(host)/vi/\(id)/hqdefault.jpg")
      precondition(urls.first?.absoluteString == standard)
      precondition(urls.count == 2 && Set(urls).count == 2)
    }
    for raw in [nil, "https://evil.example/vi/\(id)/hqdefault.jpg", "https://img.youtube.com/vi/OTHER123456/hqdefault.jpg", "http://i.ytimg.com/vi/\(id)/hqdefault.jpg"] as [String?] {
      precondition(ArtworkDownloader.candidates(videoID: id, supplied: raw).first?.absoluteString == standard)
    }
    precondition(ArtworkDownloader.candidates(videoID: "../../", supplied: nil).isEmpty)
    let large = ArtworkDownloader.candidates(videoID: id, supplied: "https://img.youtube.com/vi/\(id)/maxresdefault.jpg")
    precondition(large.count == 3 && large[1].absoluteString == standard)
    precondition(ArtworkDownloader.validImage(jpeg(width: 480, height: 360)))
    precondition(!ArtworkDownloader.validImage(jpeg(width: 120, height: 90)))
    precondition(!ArtworkDownloader.validImage(Data("<html>not a cover</html>".utf8)))
    precondition(!ArtworkDownloader.validImage(Data(repeating: 0, count: ArtworkDownloader.byteLimit + 1)))
    print("Artwork regressions passed: both hosts, same video, safe fallbacks, decoded image, placeholder/size rejection.")
  }
}
