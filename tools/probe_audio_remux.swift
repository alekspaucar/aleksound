import Foundation
import AVFoundation

// Local, non-destructive experiment: source and output must be distinct.
@main
struct AudioRemuxProbe {
  static func main() async throws {
    let args = CommandLine.arguments
    guard args.count == 3, args[1] != args[2] else { fatalError("source output") }
    let source = URL(fileURLWithPath: args[1])
    let output = URL(fileURLWithPath: args[2])
    let audio = try AVAudioFile(forReading: source)
    let seconds = Double(audio.length) / audio.processingFormat.sampleRate
    let asset = AVURLAsset(url: source)
    let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough)!
    exporter.timeRange = CMTimeRange(start: .zero, duration: CMTime(seconds: seconds, preferredTimescale: 44100))
    try await exporter.export(to: output, as: .m4a)
    let result = AVURLAsset(url: output)
    let newAudio = try AVAudioFile(forReading: output)
    print("sourceFrames=\(audio.length) sourceSeconds=\(seconds)")
    print("exportDuration=\(try await result.load(.duration).seconds) exportFrames=\(newAudio.length)")
    // Decode beginning and tail, so a duration-only metadata change can't pass.
    for start in [AVAudioFramePosition(0), max(0, newAudio.length - 44100)] {
      newAudio.framePosition = start
      let buffer = AVAudioPCMBuffer(pcmFormat: newAudio.processingFormat, frameCapacity: 44100)!
      try newAudio.read(into: buffer)
      let samples = buffer.floatChannelData![0]
      let peak = (0..<Int(buffer.frameLength)).reduce(Float(0)) { max($0, abs(samples[$1])) }
      print("decodeStart=\(start) frames=\(buffer.frameLength) peak=\(peak)")
    }
  }
}
