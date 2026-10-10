import Foundation
import AVFoundation

// Reproduce AVFoundation's handling of a finite local AAC file, no networking.
@main
struct LocalAssetProbe {
  static func main() async {
    for path in CommandLine.arguments.dropFirst() {
      let asset = AVURLAsset(url: URL(fileURLWithPath: path))
      do {
        let duration = try await asset.load(.duration).seconds
        let playable = try await asset.load(.isPlayable)
        print("\((path as NSString).pathExtension): duration=\(duration), playable=\(playable)")
        let audio = try AVAudioFile(forReading: URL(fileURLWithPath: path))
        print("frames=\(audio.length), rate=\(audio.processingFormat.sampleRate), audioDuration=\(Double(audio.length) / audio.processingFormat.sampleRate)")
        for track in try await asset.loadTracks(withMediaType: .audio) {
          print("trackRange=\(try await track.load(.timeRange))")
        }
        if let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) {
          print("passthroughTypes=\(exporter.supportedFileTypes)")
        }
      } catch {
        let error = error as NSError
        print("\((path as NSString).pathExtension): \(error.domain) / \(error.code)")
      }
    }
  }
}
