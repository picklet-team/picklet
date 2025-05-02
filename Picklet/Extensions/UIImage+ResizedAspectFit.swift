//
//  UIImage+Resized.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import UIKit

extension UIImage {
  /// 元画像をアスペクト比を保ったままリサイズし、透明な背景で正方形にパディングする
  func resizedAspectFitWithTransparentPadding(to targetSize: CGSize) -> UIImage? {
    // 1. 元画像とターゲットサイズの比率を計算
    let widthRatio = targetSize.width / size.width
    let heightRatio = targetSize.height / size.height

    // 2. 縦横の小さい方に合わせてスケール
    let scaleFactor = min(widthRatio, heightRatio)

    // 3. リサイズ後の画像サイズを決定
    let resizedSize = CGSize(
      width: size.width * scaleFactor,
      height: size.height * scaleFactor
    )

    // 4. 描画コンテキストをターゲットサイズで作成（背景は透明）
    UIGraphicsBeginImageContextWithOptions(targetSize, false, scale)

    // 5. リサイズ後の画像を中央に配置
    let origin = CGPoint(
      x: (targetSize.width - resizedSize.width) / 2,
      y: (targetSize.height - resizedSize.height) / 2
    )
    self.draw(in: CGRect(origin: origin, size: resizedSize))

    // 6. コンテキストから新しいUIImageを取り出す
    let resultImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resultImage
  }
  /// 元画像サイズにマスクを中央合わせでリサイズする
  func resizedMaskCentered(to originalSize: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(originalSize, false, scale)

    let maskSize = self.size.width  // 1024前提
    let targetLongSide = max(originalSize.width, originalSize.height)
    let scaleFactor = targetLongSide / maskSize

    let newMaskSize = CGSize(
      width: self.size.width * scaleFactor,
      height: self.size.height * scaleFactor
    )

    let origin = CGPoint(
      x: (originalSize.width - newMaskSize.width) / 2,
      y: (originalSize.height - newMaskSize.height) / 2
    )

    self.draw(in: CGRect(origin: origin, size: newMaskSize))

    let resizedMask = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedMask
  }
}
