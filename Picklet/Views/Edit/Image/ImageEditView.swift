//
//  ImageEditView.swift
//  MyApp
//
//  Created by al dente on 2025/04/29.
//

// ImageEditView.swift
import SwiftUI

struct CropingMessageView: View {
  var body: some View {
    Color.black.opacity(0.4)  // 🔲 全体を暗くする
      .ignoresSafeArea()

    VStack {
      ProgressView("AIが画像を切り抜いています")
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .foregroundColor(.primary)
    }
    .padding()
    .transition(.opacity)
  }
}

struct ImageEditView: View {
  @Binding var imageSet: EditableImageSet?

  @State private var maskedImage: UIImage?
  @State private var isCropping = true

  var body: some View {
    ZStack {
      VStack {
        if let set = imageSet {
          if isCropping {
            ImageView(image: set.original, urlStr: set.originalUrl)
          } else {
            ImageView(image: set.mask, urlStr: set.maskUrl)
          }
        } else {
          Text("画像が見つかりません")
        }
      }
      .padding()
      .task {
        await processImageSet()
      }
      if isCropping {
        CropingMessageView()
      }
    }
  }

  private func processImageSet() async {
    if let output = await CoreMLService.shared.processImageSet(imageSet: imageSet) {
      imageSet = output
      isCropping = false
    }
  }
}
