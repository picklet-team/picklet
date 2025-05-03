//
//  ImageProcessor.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import CoreImage
import UIKit

enum ImageProcessor {
    /// CIImageでマスク画像をアルファに変換 → 合成
    static func applyMask(original: UIImage, mask: UIImage) -> UIImage? {
        guard let ciOriginal = CIImage(image: original),
              let ciMask = CIImage(image: mask)
        else { return nil }

        let alphaMask =
            ciMask
            .applyingFilter("CIColorInvert")
            .applyingFilter("CIMaskToAlpha")

        let composited =
            ciOriginal
            .applyingFilter(
                "CIBlendWithAlphaMask",
                parameters: [
                    "inputMaskImage": alphaMask
                ])

        let context = CIContext()
        guard let output = context.createCGImage(composited, from: ciOriginal.extent) else {
            return nil
        }

        return UIImage(cgImage: output)
    }

    /// 完成画像とマスクを合成して、マスク範囲を黒く強調するビジュアライズ画像を作る
    static func visualizeMaskOnOriginal(original: UIImage, mask: UIImage) -> UIImage? {
        guard let ciOriginal = CIImage(image: original),
              let ciMask = CIImage(image: mask)
        else {
            return nil
        }

        // マスクの白い部分だけを透明にする（マスクが黒いところが残る）
        let alphaMask =
            ciMask
            .applyingFilter("CIColorInvert")
            .applyingFilter("CIMaskToAlpha")

        let maskedImage =
            ciOriginal
            .applyingFilter(
                "CIBlendWithAlphaMask",
                parameters: [
                    "inputMaskImage": alphaMask
                ]
            )
            .applyingFilter(
                "CIColorControls",
                parameters: [
                    "inputBrightness": -1.0  // 黒くする
                ])

        let context = CIContext()
        guard let output = context.createCGImage(maskedImage, from: ciOriginal.extent) else {
            return nil
        }

        return UIImage(cgImage: output)
    }
}
