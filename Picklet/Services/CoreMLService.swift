//
//  CoreMLService.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import CoreML
import SwiftUI

class CoreMLService {
  static let shared = CoreMLService()

  private let model: ISNet

  init() {
    self.model = try! ISNet(configuration: MLModelConfiguration())
  }

  func processImageSet(imageSet: EditableImageSet?) async -> EditableImageSet? {
    // ① imageSet自体の存在をチェック
    guard var set = imageSet else {
      print("❌ imageSet is nil")
      return nil
    }

    // ② original が nil なら URL からダウンロード
    if set.original == nil,
      let urlStr = set.originalUrl,
      let url = URL(string: urlStr)
    {
      do {
        let (data, _) = try await URLSession.shared.data(from: url)
        if let image = UIImage(data: data) {
          set.original = image
        } else {
          print("❌ failed to decode image from data")
          return nil
        }
      } catch {
        print("❌ failed to download image:", error)
        return nil
      }
    }

    // ③ original が still nil の場合 → 処理不可
    guard let original = set.original else {
      print("❌ original image not available")
      return nil
    }

    // ④ CoreML によるマスク推論
    guard let mask = await self.predictMask(for: original) else {
      print("❌ mask prediction failed")
      return nil
    }

    // ⑤ マスクを使って切り抜き画像を生成
    guard let result = ImageProcessor.applyMask(original: original, mask: mask) else {
      print("❌ mask application failed")
      return nil
    }

    // ⑥ 加工結果を保存して返す
    set.mask = mask
    set.result = result
    return set
  }

  func processImage(image: UIImage) async -> UIImage? {
    // 1. 推論
    guard let mask = await self.predictMask(for: image) else {
      print("❌ mask prediction failed")
      return nil
    }

    guard let result = ImageProcessor.applyMask(original: image, mask: mask) else {
      print("❌ mask application failed")
      return nil
    }
    return result
  }

  func predictMask(
    for image: UIImage,
    flipHorizontally: Bool = true
  ) async -> UIImage? {
    let targetSize = CGSize(width: 1024, height: 1024)

    // 1. 推論用にリサイズ
    guard let resizedInput = image.resizedAspectFitWithTransparentPadding(to: targetSize),
      let pixelBuffer = resizedInput.pixelBuffer(
        width: Int(targetSize.width), height: Int(targetSize.height))
    else {
      print("❌ pixelBuffer生成失敗")
      return nil
    }

    do {
      // 2. 推論
      let output = try model.prediction(x_1: pixelBuffer)
      guard var maskImage = UIImage(pixelBuffer: output.activation_out) else {
        print("❌ マスク画像作成失敗")
        return nil
      }

      // ---ここからマスク加工---

      // 4. マスクを元画像サイズにリサイズ（元画像と同じ）
      guard let resizedMask = maskImage.resizedMaskCentered(to: image.size) else {
        print("❌ マスクリサイズ失敗")
        return nil
      }

      maskImage = resizedMask

      // 5. マスクを左右反転（必要なら）
      if flipHorizontally {
        maskImage = maskImage.flippedHorizontally() ?? maskImage
      }

      // 6. マスクを白黒反転
      guard let invertedMask = maskImage.invertedMask() else {
        print("❌ マスク白黒反転失敗")
        return nil
      }

      // ---マスク加工ここまで---

      return invertedMask

    } catch {
      print("❌ 推論失敗: \(error.localizedDescription)")
      return nil
    }
  }

}
