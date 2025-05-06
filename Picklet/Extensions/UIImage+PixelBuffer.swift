//
//  UIImage+PixelBuffer.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import UIKit

extension UIImage {
  func pixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
    let attrs =
      [
        kCVPixelBufferCGImageCompatibilityKey: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true
      ] as CFDictionary
    var pixelBuffer: CVPixelBuffer?

    let status = CVPixelBufferCreate(
      kCFAllocatorDefault,
      width,
      height,
      kCVPixelFormatType_32ARGB,
      attrs,
      &pixelBuffer)

    guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }

    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let context = CGContext(
      data: CVPixelBufferGetBaseAddress(buffer),
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    guard let cgImage = cgImage else { return nil }

    context?.saveGState()
    context?.translateBy(x: 0, y: CGFloat(height))
    context?.scaleBy(x: 1.0, y: -1.0) // 上下反転で正しい方向に描画される
    context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    context?.restoreGState()

    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

    return buffer
  }

  convenience init?(pixelBuffer: CVPixelBuffer) {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let context = CIContext()
    guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
    self.init(cgImage: cgImage)
  }
}
