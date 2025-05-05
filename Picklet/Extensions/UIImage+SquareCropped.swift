//
//  UIImage+SquareCropped.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import UIKit

extension UIImage {
  /// Crops the image to a square from the center
  func squareCropped() -> UIImage {
    let minEdge = min(size.width, size.height)
    let originX = (size.width - minEdge) / 2
    let originY = (size.height - minEdge) / 2
    let cropRect = CGRect(x: originX, y: originY, width: minEdge, height: minEdge)
    guard let cgCropped = cgImage?.cropping(to: cropRect) else { return self }
    return UIImage(cgImage: cgCropped, scale: scale, orientation: imageOrientation)
  }
}
