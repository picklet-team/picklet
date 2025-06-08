//
//  CaptureOrLibraryView.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI

struct CaptureOrLibraryView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  var onImagePicked: (UIImage) -> Void
  var onCancel: (() -> Void)?

  @Environment(\.dismiss) private var dismiss

  @State private var showCamera = true
  @State private var didPickImage = false

  var body: some View {
    ZStack {
      // 背景グラデーション
      themeManager.currentTheme.backgroundGradient
        .ignoresSafeArea()

      VStack(spacing: 0) {
        ZStack {
          if showCamera {
            CameraSquarePreviewView { image in
              didPickImage = true
              onImagePicked(image)
              dismiss()
            }
            .environmentObject(themeManager) // テーマを渡す
          } else {
            PhotoLibraryPickerView { image in
              onImagePicked(image)
              dismiss()
            }
            .environmentObject(themeManager) // テーマを渡す
          }
        }
        .frame(maxHeight: .infinity)

        ModeSwitchBarView(
          isCameraSelected: showCamera,
          onCamera: { showCamera = true },
          onLibrary: { showCamera = false })
          .environmentObject(themeManager) // テーマを渡す
          .ignoresSafeArea()
      }
    }
    .onDisappear {
      if !didPickImage {
        onCancel?()
      }
    }
    .tint(themeManager.currentTheme.accentColor) // 全体のアクセントカラーを統一
  }
}
