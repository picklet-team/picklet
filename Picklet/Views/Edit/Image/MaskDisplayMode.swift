//
//  MaskDisplayMode.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SwiftUI

struct MaskEditorView: View {
  @Binding var imageSet: EditableImageSet
  @Environment(\.dismiss) var dismiss

  // MARK: - State

  @State private var zoomScale: CGFloat = 1
  @State private var offset: CGSize = .zero
  @State private var displayImage: UIImage? // 表示用画像を追跡

  var body: some View {
    NavigationView {
      GeometryReader { geo in
        ZStack {
          // 背景
          Color(.systemBackground).edgesIgnoringSafeArea(.all)

          // 画像表示 - Optionalバインディングのエラー修正
          let imageToDisplay = displayImage ?? imageSet.original
          Image(uiImage: imageToDisplay)
            .resizable()
            .scaledToFit()
            .scaleEffect(zoomScale)
            .offset(offset)
            .frame(width: geo.size.width, height: geo.size.height)
        }
      }
      .navigationTitle("画像編集")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("キャンセル") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("完了") {
            // 変更があれば適用して閉じる
            dismiss()
          }
        }
      }
      .onAppear {
        // 画像ロード確認用デバッグ
        print("🖼️ MaskEditorView表示 - ID: \(imageSet.id)")
        print("👁️ 画像情報: originalURL=\(imageSet.originalUrl ?? "nil"), isNew=\(imageSet.isNew)")

        // 表示用画像を設定（original画像が確実に存在するはず）
        displayImage = imageSet.original

        if imageSet.original.size.width < 50 || imageSet.original.size.height < 50 {
          print("⚠️ 警告: 不適切なサイズの画像です: \(imageSet.original.size)")
        }
      }
    }
  }

  // ズームとパン用ジェスチャー (必要に応じて実装)
  private func zoomPanGesture() -> some Gesture {
    SimultaneousGesture(
      MagnificationGesture()
        .onChanged { value in
          zoomScale = value
        },
      DragGesture()
        .onChanged { value in
          offset = value.translation
        })
  }
}
