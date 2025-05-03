//
//  ImageListView.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//


import SwiftUI

/// 画像サムネイル一覧と追加ボタンを表示するサブビュー
struct ImageListView: View {
  @Binding var imageSets: [EditableImageSet]
  let onAdd: () -> Void
  let onSelect: (EditableImageSet) -> Void

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        // 既存画像サムネイル
        ForEach(imageSets.indices, id: \.self) { index in
          let set = imageSets[index]
          Button(action: { onSelect(set) }) {
            ZStack {
              let displayImage = set.result ?? set.original
              Image(uiImage: displayImage)
                .resizable()
                .scaledToFill()
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(4)
          }
        }
        // 追加ボタン
        Button(action: onAdd) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 60, height: 60)
                Image(systemName: "plus")
                    .font(.title)
            }
        }
      }
      .padding(.horizontal)
    }
  }
}
