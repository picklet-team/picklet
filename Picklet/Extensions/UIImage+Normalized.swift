//
//  UIImage+Normalized.swift
//  Picklet
//
//  Created by al dente on 2025/04/29.
//

import UIKit

extension UIImage {
  func normalized() -> UIImage {
    if imageOrientation == .up {
      return self // 問題なし
    }

    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    draw(in: CGRect(origin: .zero, size: size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage ?? self
  }
}
