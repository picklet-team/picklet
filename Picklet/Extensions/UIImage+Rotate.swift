//
//  UIImage+Rotate.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import UIKit

extension UIImage {
  /// 任意の角度（度数）で画像を回転する
  func rotated(byDegrees degrees: CGFloat) -> UIImage? {
    let radians = degrees * (.pi / 180)
    let newSize = CGRect(origin: .zero, size: size)
      .applying(CGAffineTransform(rotationAngle: radians))
      .integral.size

    UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
    guard let context = UIGraphicsGetCurrentContext(), let cgImage = cgImage else {
      return nil
    }

    context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
    context.rotate(by: radians)
    context.scaleBy(x: 1.0, y: -1.0) // UIKitの上下反転補正

    context.draw(
      cgImage,
      in: CGRect(
        x: -size.width / 2, y: -size.height / 2,
        width: size.width, height: size.height
      )
    )

    let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return rotatedImage
  }
}
