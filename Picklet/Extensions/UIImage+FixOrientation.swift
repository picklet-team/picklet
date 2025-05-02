//
//  UIImage+FixOrientation.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import UIKit

extension UIImage {
  /// 画像の上下左右の向きを .up に正規化する
  func fixedOrientation() -> UIImage {
    if imageOrientation == .up {
      return self
    }

    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    draw(in: CGRect(origin: .zero, size: size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    return normalizedImage
  }
}
