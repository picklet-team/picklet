//
//  CameraSquarePreviewView.swift
//  Picklet
//
//  Created by al dente on 2025/04/30.
//

import SwiftUI

struct CameraSquarePreviewView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  let onCaptured: (UIImage) -> Void
  @State private var shouldCapture = false

  var body: some View {
    GeometryReader { geo in
      let size = min(geo.size.width, geo.size.height)

      ZStack {
        CameraPreviewView(onImageCaptured: onCaptured, triggerCapture: $shouldCapture)
          .frame(width: size, height: size)
          .clipped()

        VStack {
          Spacer()

          // カスタムシャッターボタン
          Button(action: {
            shouldCapture = true
          }) {
            ZStack {
              Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
                .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)

              Circle()
                .stroke(themeManager.currentTheme.primaryColor, lineWidth: 3)
                .frame(width: 60, height: 60)

              Circle()
                .fill(themeManager.currentTheme.primaryColor)
                .frame(width: 50, height: 50)
            }
          }
          .padding(.bottom, 40)
        }
      }
    }
  }
}
