//
//  CoreMLService.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI
import CoreML

class CoreMLService {
    static let shared = CoreMLService()

    private let model: ISNet

    init() {
        self.model = try! ISNet(configuration: MLModelConfiguration())
    }


    func processImage(image: UIImage) async -> UIImage? {
        // 1. 推論
        if let finalMask = CoreMLService.shared.predictMask(for: image) {
            guard let maskedImage = ImageProcessor.applyMask(original: image, mask: finalMask) else {
                return nil
            }
            return maskedImage
        }
        return nil

    }

    func predictMask(for image: UIImage,
                     flipHorizontally: Bool = true) -> UIImage? {
        let targetSize = CGSize(width: 1024, height: 1024)

        // 1. 推論用にリサイズ
        guard let resizedInput = image.resizedAspectFitWithTransparentPadding(to: targetSize),
              let pixelBuffer = resizedInput.pixelBuffer(width: Int(targetSize.width), height: Int(targetSize.height)) else {
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
