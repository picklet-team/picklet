//
//  ModeSwitchBarView.swift
//  Picklet
//
//  Created by al dente on 2025/04/30.
//

import SwiftUI

struct ModeSwitchBarView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  let isCameraSelected: Bool
  let onCamera: () -> Void
  let onLibrary: () -> Void

  var body: some View {
    HStack {
      modeButton(
        icon: "camera",
        title: "カメラ",
        isSelected: isCameraSelected,
        action: onCamera)
        .accessibility(identifier: "cameraButton")

      modeButton(
        icon: "photo.on.rectangle",
        title: "ライブラリ",
        isSelected: !isCameraSelected,
        action: onLibrary)
        .accessibility(identifier: "libraryButton")
    }
    .padding()
    .background(
      // グラデーション背景を適用
      LinearGradient(
        colors: [
          Color(.systemBackground).opacity(0.95),
          Color(.secondarySystemBackground).opacity(0.95)
        ],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }

  private func modeButton(
    icon: String,
    title: String,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Image(systemName: icon)
          .font(.title2)
          .fontWeight(isSelected ? .semibold : .regular)

        Text(title)
          .font(.caption)
          .fontWeight(isSelected ? .medium : .regular)
      }
      .foregroundColor(isSelected ? themeManager.currentTheme.primaryColor : .secondary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(isSelected ? themeManager.currentTheme.primaryColor.opacity(0.1) : Color.clear)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}
