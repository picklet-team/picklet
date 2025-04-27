//
//  ClothingCropEditView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI

struct ClothingCropEditView: View {
    let originalImage: UIImage
    let onComplete: (UIImage) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var maskedImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("AIが服を切り抜いています…")
                    .padding()
            } else if let result = maskedImage {
                Image(uiImage: result)
                    .resizable()
                    .scaledToFit()
                    .padding()

                Button("登録する") {
                    onComplete(result)
                    dismiss()
                }
                .padding()
            } else {
                Text("切り抜きに失敗しました")
                Button("戻る") {
                    dismiss()
                }
                .padding()
            }
        }
        .navigationTitle("画像編集")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await processImage()
        }
    }

    private func processImage() async {
        if let output = await CoreMLService.shared.processImage(image: originalImage) {
            self.maskedImage = output
        }
        self.isLoading = false
    }
}
