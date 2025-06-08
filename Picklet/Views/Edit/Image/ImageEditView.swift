//
//  ImageEditView.swift
//  Picklet
//
//  Created by al dente on 2025/04/29.
//

// ImageEditView.swift
import SwiftUI

struct CropingMessageView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加

  var body: some View {
    ZStack {
      Color.black.opacity(0.4) // 全体を暗くする
        .ignoresSafeArea()

      VStack {
        ProgressView("AIが画像を切り抜いています")
          .tint(themeManager.currentTheme.primaryColor) // テーマカラーを適用
          .padding()
          .background(.ultraThinMaterial)
          .cornerRadius(12)
          .foregroundColor(.primary)
      }
      .padding()
      .transition(.opacity)
    }
  }
}

struct ImageEditView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  @StateObject private var viewModel: ImageEditViewModel
  @Binding var imageSet: EditableImageSet?

  var body: some View {
    ZStack {
      // 背景グラデーション
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      VStack {
        if viewModel.isProcessing {
          ProgressView("処理中…")
            .tint(themeManager.currentTheme.primaryColor) // テーマカラーを適用
        } else {
          Image(uiImage: viewModel.imageSet.mask ?? viewModel.imageSet.original)
            .resizable()
            .scaledToFit()
        }
      }
    }
    .onAppear { viewModel.runSegmentation() }
  }
}
