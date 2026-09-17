// xcrun swiftc App/Services/AudioService.swift scripts/check-death-sounds.swift -o /tmp/check-death-sounds
// /tmp/check-death-sounds [directory containing the bundled death sound]
// Decode the actual imported clips without playing through any audio output.
import Foundation
import AVFAudio

@main struct DeathSoundChecks {
    static func main() throws {
        let directory = CommandLine.arguments.dropFirst().first ?? "App/Resources/GameAssets/DeathSounds"
        var report: [[String: Any]] = []
        precondition(Set(DeathSoundCatalog.filenames).count == 1)
        let base = URL(fileURLWithPath: directory, isDirectory: true)
        let cues = DeathSoundCatalog.filenames.map {
            base.appendingPathComponent($0 + "." + DeathSoundCatalog.fileExtension)
        } + [base.deletingLastPathComponent().appendingPathComponent("fuel-explosion.mp3")]
        for url in cues {
            let player = try AVAudioPlayer(contentsOf: url)
            precondition(player.duration.isFinite && player.duration > 0)
            let file = try AVAudioFile(forReading: url)
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: 4096)!
            var frames: Int64 = 0
            var peak: Float = 0
            while file.framePosition < file.length {
                try file.read(into: buffer)
                guard buffer.frameLength > 0 else { break }
                frames += Int64(buffer.frameLength)
                guard let channels = buffer.floatChannelData else { fatalError("Float decode expected") }
                for channel in 0..<Int(buffer.format.channelCount) {
                    for index in 0..<Int(buffer.frameLength) {
                        let sample = channels[channel][index]
                        precondition(sample.isFinite)
                        peak = max(peak, abs(sample))
                    }
                }
            }
            precondition(frames == file.length && frames > 0, "The complete clip must decode")
            report.append(["file": url.lastPathComponent, "seconds": player.duration,
                           "decodedFrames": frames, "peak": peak,
                           "endlessFinalMinimum": max(1.8, player.duration),
                           "slowMotionMinimum": max(3.6, player.duration)])
        }
        let data = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        print(String(decoding: data, as: UTF8.self))
    }
}
