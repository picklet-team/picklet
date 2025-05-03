//
//  UIImage+FlippedHorizontally.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import UIKit

extension UIImage {
  func flippedHorizontally() -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    let context = UIGraphicsGetCurrentContext()
    context?.translateBy(x: 0, y: size.height)
    context?.scaleBy(x: 1, y: -1)
    draw(in: CGRect(origin: .zero, size: size))
    let flippedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return flippedImage
  }
}
