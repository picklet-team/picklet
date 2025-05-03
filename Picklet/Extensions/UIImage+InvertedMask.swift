//
//  UIImage+InvertedMask.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import CoreImage
import UIKit

extension UIImage {
  func invertedMask() -> UIImage? {
    guard let ciImage = CIImage(image: self) else { return nil }

    let filter = CIFilter(name: "CIColorInvert")
    filter?.setValue(ciImage, forKey: kCIInputImageKey)

    guard let outputImage = filter?.outputImage else { return nil }
    let context = CIContext()
    if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
      return UIImage(cgImage: cgImage)
    }
    return nil
  }
}
