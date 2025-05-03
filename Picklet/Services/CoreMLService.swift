//
//  CoreMLService.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import CoreML
import SwiftUI

class CoreMLService {
    static let shared = CoreMLService()
    private let model: ISNet

    init() {
        do {
            self.model = try ISNet(configuration: MLModelConfiguration())
        } catch {
            fatalError("ISNetモデルの初期化に失敗しました: \(error.localizedDescription)")
        }
    }

    func processImageSet(imageSet: EditableImageSet) async -> EditableImageSet? {
        let original = imageSet.original

        guard let mask = await self.predictMask(for: original) else {
            print("❌ mask prediction failed")
            return nil
        }

        guard let result = ImageProcessor.applyMask(original: original, mask: mask) else {
            print("❌ mask application failed")
            return nil
        }

        var newSet = imageSet
        newSet.mask = mask
        newSet.result = result
        return newSet
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
                width: Int(targetSize.width), height: Int(targetSize.height)
              ) else {
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
