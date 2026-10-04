import AVFoundation
import CoreGraphics
import Foundation
import ImageIO

// Package the harness's real rendered frames; this does not alter source art.
// swift scripts/rider-preview/MakePreviewMovie.swift input-directory output.mp4
precondition(CommandLine.arguments.count == 3, "Usage: MakePreviewMovie.swift frame-directory output.mp4")
let inputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])
precondition(!FileManager.default.fileExists(atPath: outputURL.path), "Output already exists")
let frames = (0..<180).map { inputDirectory.appendingPathComponent(String(format: "motion-%03d.png", $0)) }
precondition(frames.allSatisfy { FileManager.default.fileExists(atPath: $0.path) },
             "Export all 180 frames with RIDER_PREVIEW_ALL_FRAMES=1 first")
func read(_ url: URL) -> CGImage {
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    return CGImageSourceCreateImageAtIndex(source, 0, nil)!
}
let first = read(frames[0])
let width = first.width, height = first.height
let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width, AVVideoHeightKey: height,
    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000],
])
input.expectsMediaDataInRealTime = false
let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
    kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
    kCVPixelBufferCGImageCompatibilityKey as String: true,
    kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
])
precondition(writer.canAdd(input))
writer.add(input)
precondition(writer.startWriting(), writer.error?.localizedDescription ?? "Cannot start video writer")
writer.startSession(atSourceTime: .zero)
for (index, frame) in frames.enumerated() {
    let deadline = Date().addingTimeInterval(15)
    while !input.isReadyForMoreMediaData && writer.status == .writing && Date() < deadline {
        Thread.sleep(forTimeInterval: 0.001)
    }
    precondition(input.isReadyForMoreMediaData, writer.error?.localizedDescription ?? "Video writer timed out")
    autoreleasepool {
        var pixelBuffer: CVPixelBuffer?
        precondition(CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pixelBuffer) == kCVReturnSuccess)
        let buffer = pixelBuffer!
        CVPixelBufferLockBaseAddress(buffer, [])
        let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)!
        let image = read(frame)
        precondition(image.width == width && image.height == height, "Inconsistent frame dimensions")
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        CVPixelBufferUnlockBaseAddress(buffer, [])
        precondition(adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(index), timescale: 60)),
                     writer.error?.localizedDescription ?? "Cannot append frame")
    }
}
input.markAsFinished()
let completed = DispatchSemaphore(value: 0)
writer.finishWriting { completed.signal() }
precondition(completed.wait(timeout: .now() + 30) == .success, "Video writer did not finish")
precondition(writer.status == .completed, writer.error?.localizedDescription ?? "Video writer failed")
print("Wrote 180 native frames at 60 fps: \(outputURL.path)")
