import Foundation
import AVFoundation
import CryptoKit

// Compile together with ios/Runner/AudioFileFinalizer.swift. A local copy of
// a fragmented download is the fixture; this harness never changes its source.
@main
struct AudioFinalizerRegression {
  static func decodedHash(_ url: URL) throws -> SHA256.Digest {
    let audio = try AVAudioFile(forReading: url)
    let buffer = AVAudioPCMBuffer(pcmFormat: audio.processingFormat, frameCapacity: 8192)!
    var hash = SHA256()
    while audio.framePosition < audio.length {
      try audio.read(into: buffer)
      guard buffer.frameLength > 0 else { throw AudioFileFinalizer.InvalidAudio() }
      for channel in 0..<Int(buffer.format.channelCount) {
        hash.update(data: Data(bytes: buffer.floatChannelData![channel], count: Int(buffer.frameLength) * MemoryLayout<Float>.size))
      }
    }
    return hash.finalize()
  }

  static func main() async throws {
    let args = CommandLine.arguments
    guard args.count == 3 else { fatalError("source new-output") }
    let source = URL(fileURLWithPath: args[1]), output = URL(fileURLWithPath: args[2])
    let sourceHash = SHA256.hash(data: try Data(contentsOf: source))
    let prepared = try await AudioFileFinalizer.prepare(source: source, destination: output)
    let audio = try AVAudioFile(forReading: source)
    let actual = Double(audio.length) / audio.processingFormat.sampleRate
    precondition(abs(prepared.duration - actual) < 0.1)
    let decodedSource = try decodedHash(source), decodedOutput = try decodedHash(output)
    let sourceAfter = SHA256.hash(data: try Data(contentsOf: source))
    precondition(decodedSource == decodedOutput, "The complete decoded audio must remain identical.")
    precondition(sourceHash == sourceAfter, "The original must be untouched.")
    do {
      _ = try await AudioFileFinalizer.prepare(source: source, destination: output)
      fatalError("Existing output must never be overwritten.")
    } catch is AudioFileFinalizer.InvalidAudio { }
    print("PASS: duration=\(prepared.duration); all decoded samples identical; original intact; overwrite rejected.")
  }
}
