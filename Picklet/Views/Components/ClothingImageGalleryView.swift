import SDWebImageSwiftUI
import SwiftUI

/// 服の画像一覧を表示する共通コンポーネント
struct ClothingImageGalleryView: View {
  @Binding var imageSets: [EditableImageSet] // バインディングに変更
  let imageSize: CGFloat
  let cornerRadius: CGFloat
  let spacing: CGFloat
  let showsIndicators: Bool
  var onSelectImage: ((EditableImageSet) -> Void)?
  var showAddButton: Bool
  var onAddButtonTap: (() -> Void)?

  init(
    imageSets: Binding<[EditableImageSet]>, // バインディングパラメータに変更
    imageSize: CGFloat = 150,
    cornerRadius: CGFloat = 8,
    spacing: CGFloat = 12,
    showsIndicators: Bool = false,
    showAddButton: Bool = false,
    onSelectImage: ((EditableImageSet) -> Void)? = nil,
    onAddButtonTap: (() -> Void)? = nil) {
    _imageSets = imageSets // _で始まる変数にバインディングを割り当て
    self.imageSize = imageSize
    self.cornerRadius = cornerRadius
    self.spacing = spacing
    self.showsIndicators = showsIndicators
    self.showAddButton = showAddButton
    self.onSelectImage = onSelectImage
    self.onAddButtonTap = onAddButtonTap
  }

  var body: some View {
    ScrollView(.horizontal, showsIndicators: showsIndicators) {
      HStack(spacing: spacing) {
        // 既存の画像アイテム
        ForEach(imageSets) { set in
          ImageThumbnailView(
            imageURL: set.originalUrl,
            size: imageSize,
            cornerRadius: cornerRadius)
            .onTapGesture {
              if let onSelect = onSelectImage {
                onSelect(set)
              }
            }
        }

        // シンプルな追加ボタン
        if showAddButton, let addAction = onAddButtonTap {
          Button(action: addAction) {
            ZStack {
              RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .overlay(
                  RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1))
                .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)

              Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.blue)
            }
            .frame(width: imageSize, height: imageSize)
          }
        }
      }
      .padding()
    }
  }
}

// 読み取り専用バージョン（既存のコードとの互換性のため）
extension ClothingImageGalleryView {
  init(
    imageSets: [EditableImageSet],
    imageSize: CGFloat = 150,
    cornerRadius: CGFloat = 8,
    spacing: CGFloat = 12,
    showsIndicators: Bool = false,
    showAddButton: Bool = false,
    onSelectImage: ((EditableImageSet) -> Void)? = nil,
    onAddButtonTap: (() -> Void)? = nil) {
    self.init(
      imageSets: .constant(imageSets), // 固定値のバインディングを作成
      imageSize: imageSize,
      cornerRadius: cornerRadius,
      spacing: spacing,
      showsIndicators: showsIndicators,
      showAddButton: showAddButton,
      onSelectImage: onSelectImage,
      onAddButtonTap: onAddButtonTap)
  }
}

struct ImageThumbnailView: View {
  let imageURL: String?
  let size: CGFloat
  let cornerRadius: CGFloat

  var body: some View {
    Group {
      if let urlString = imageURL, let url = URL(string: urlString) {
        WebImage(
          url: url,
          options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
          .resizable()
          .indicator(.activity)
      } else {
        Rectangle().fill(Color.gray.opacity(0.2))
      }
    }
    .scaledToFill()
    .frame(width: size, height: size)
    .clipped()
    .cornerRadius(cornerRadius)
  }
}
