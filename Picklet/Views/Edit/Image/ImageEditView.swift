//
//  ImageEditView.swift
//  Picklet
//
//  Created by al dente on 2025/04/29.
//

// ImageEditView.swift
import SwiftUI

struct CropingMessageView: View {
  var body: some View {
    Color.black.opacity(0.4) // 🔲 全体を暗くする
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
  @StateObject private var viewModel: ImageEditViewModel
  @Binding var imageSet: EditableImageSet?

//  @State private var isCropping = true

  var body: some View {
    VStack {
      if viewModel.isProcessing {
        ProgressView("処理中…")
      } else {
        Image(uiImage: viewModel.imageSet.mask ?? viewModel.imageSet.original)
          .resizable()
          .scaledToFit()
      }
    }
    .onAppear { viewModel.runSegmentation() }
  }
}
