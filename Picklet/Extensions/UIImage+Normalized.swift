//
//  UIImage+Normalized.swift
//  Picklet
//
//  Created by al dente on 2025/04/29.
//

import UIKit

extension UIImage {
  func normalized() -> UIImage {
    if self.imageOrientation == .up {
      return self  // 問題なし
    }

    UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
    self.draw(in: CGRect(origin: .zero, size: self.size))
    let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return normalizedImage ?? self
  }
}
