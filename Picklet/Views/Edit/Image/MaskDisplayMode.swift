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
  @EnvironmentObject var themeManager: ThemeManager

  // MARK: - State

  @State private var zoomScale: CGFloat = 1
  @State private var offset: CGSize = .zero
  @State private var displayImage: UIImage? // 表示用画像を追跡
  @State private var showDeleteConfirm = false

  var body: some View {
    NavigationView {
      ZStack {
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

        // 削除ボタンを下部に配置
        VStack {
          Spacer()

          HStack {
            Spacer()

            Button(action: { showDeleteConfirm = true }, label: {
              HStack {
                Image(systemName: "trash")
                Text("削除")
              }
              .foregroundColor(.white)
              .padding(.horizontal, 20)
              .padding(.vertical, 12)
              .background(Color.red)
              .cornerRadius(25)
            })

            Spacer()
          }
          .padding(.bottom, 50)
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
      .alert("画像を削除", isPresented: $showDeleteConfirm) {
        Button("削除", role: .destructive) {
          deleteImage()
        }
        Button("キャンセル", role: .cancel) {}
      } message: {
        Text("この画像を削除しますか？この操作は取り消せません。")
      }
    }
  }

  private func deleteImage() {
    // 削除フラグを設定して親ビューに通知
    // imageSetをnilにして削除を示す
    dismiss()

    // 削除処理は親ビューで行う必要があるため、
    // NotificationCenterを使用して削除を通知
    NotificationCenter.default.post(
      name: NSNotification.Name("DeleteImageSet"),
      object: imageSet.id
    )
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
