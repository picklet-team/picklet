//
//  ClothingCropPreviewView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI

struct ClothingCropPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let originalImage: UIImage
    var onConfirm: (UIImage) -> Void
    var onRetry: () -> Void

    @State private var maskedImage: UIImage?
    @State private var maskVisualizationImage: UIImage?
    @State private var progress: Double = 0.0
    @State private var isAnimating = false

    @State private var isLoading = true
    @State private var timer: Timer?

    var body: some View {
        VStack {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView("AIが服を切り抜いています…")
                    Text("お使いのiPhone上でAIが動作中です")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
            } else {
                if let masked = maskedImage, let maskVisual = maskVisualizationImage {
                    ZStack {
                        Image(uiImage: masked)
                            .resizable()
                            .scaledToFit()
                            .opacity(1.0 - progress)

                        Image(uiImage: maskVisual)
                            .resizable()
                            .scaledToFit()
                            .opacity(progress)
                    }
                    .animation(.easeInOut(duration: 1.5), value: progress)
                    .padding()

                    HStack {
                        Button("やり直す") {
                            stopAnimation()
                            onRetry()
                        }
                        .padding()

                        Button("この画像で登録") {
                            stopAnimation()
                            onConfirm(masked)
                            dismiss()
                        }
                        .padding()
                    }
                } else {
                    Text("切り抜きに失敗しました")
                    Button("やり直す") {
                        stopAnimation()
                        onRetry()
                    }
                }
            }
        }
        .onAppear {
            print("🛠 CropPreviewView appeared！originalImageあり")

            Task {
                print("🛠 CoreML processImage開始")

                let inputImage = originalImage.fixedOrientation()

                if let final = await CoreMLService.shared.processImage(image: inputImage),
                   let maskOnly = CoreMLService.shared.predictMask(for: inputImage) {

                    self.maskedImage = final
                    self.maskVisualizationImage = ImageProcessor.visualizeMaskOnOriginal(original: inputImage, mask: maskOnly)

                    print("🛠 maskedImageとmaskVisualizationImageセット完了！")

                    startAnimation()
                } else {
                    print("❌ maskedImage作成失敗")
                }

                self.isLoading = false
            }
        }
        .onDisappear {
            stopAnimation()
        }
    }

    // ⭐️ アニメーションスタート
    private func startAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.5)) {
                self.progress = (self.progress == 1.0) ? 0.0 : 1.0
            }
        }
    }

    // ⭐️ アニメーションストップ
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}
