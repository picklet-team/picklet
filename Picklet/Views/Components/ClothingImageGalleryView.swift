import SDWebImageSwiftUI
import SwiftUI

/// 服の画像一覧を表示する共通コンポーネント
struct ClothingImageGalleryView: View {
  @EnvironmentObject var themeManager: ThemeManager // 追加
  @Binding var imageSets: [EditableImageSet]
  let imageSize: CGFloat
  let cornerRadius: CGFloat
  let spacing: CGFloat
  let showsIndicators: Bool
  var onSelectImage: ((EditableImageSet) -> Void)?
  var showAddButton: Bool
  var onAddButtonTap: (() -> Void)?

  init(
    imageSets: Binding<[EditableImageSet]>,
    imageSize: CGFloat = 150,
    cornerRadius: CGFloat = 8,
    spacing: CGFloat = 12,
    showsIndicators: Bool = false,
    showAddButton: Bool = false,
    onSelectImage: ((EditableImageSet) -> Void)? = nil,
    onAddButtonTap: (() -> Void)? = nil) {
    _imageSets = imageSets
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
            image: set.original,
            imageURL: set.originalUrl,
            size: imageSize,
            cornerRadius: cornerRadius)
            .environmentObject(themeManager) // テーマを渡す
            .onTapGesture {
              if let onSelect = onSelectImage {
                onSelect(set)
              }
            }
        }

        // テーマカラーを適用した追加ボタン
        if showAddButton, let addAction = onAddButtonTap {
          Button(action: addAction) {
            ZStack {
              RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(.systemBackground))
                .overlay(
                  RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(
                      themeManager.currentTheme.primaryColor.opacity(0.3),
                      lineWidth: 2) // テーマカラーの境界線
                )
                .shadow(
                  color: themeManager.currentTheme.primaryColor.opacity(0.1),
                  radius: 3, x: 0, y: 2) // テーマカラーの影

              VStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                  .font(.title)
                  .foregroundColor(themeManager.currentTheme.primaryColor)

                Text("追加")
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundColor(themeManager.currentTheme.primaryColor)
              }
            }
            .frame(width: imageSize, height: imageSize)
          }
          .buttonStyle(PlainButtonStyle())
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
      imageSets: .constant(imageSets),
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
  @EnvironmentObject var themeManager: ThemeManager // 追加
  let imageURL: String?
  let size: CGFloat
  let cornerRadius: CGFloat
  let image: UIImage?

  // 既存のイニシャライザをオーバーロード（下位互換性のため）
  init(imageURL: String?, size: CGFloat, cornerRadius: CGFloat) {
    self.imageURL = imageURL
    self.size = size
    self.cornerRadius = cornerRadius
    image = nil
  }

  // 新しいイニシャライザを追加
  init(image: UIImage?, imageURL: String? = nil, size: CGFloat, cornerRadius: CGFloat) {
    self.image = image
    self.imageURL = imageURL
    self.size = size
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    Group {
      if let urlString = imageURL, let url = URL(string: urlString) {
        // URLがある場合はWebImageを使用
        WebImage(
          url: url,
          options: [.queryMemoryData, .queryDiskDataSync, .refreshCached])
          .resizable()
          .indicator(.activity) // シンプルなアクティビティインジケーター
      } else if let uiImage = image {
        // URLがなくUIImageがある場合は直接表示
        Image(uiImage: uiImage)
          .resizable()
      } else {
        // どちらもない場合はテーマカラーのプレースホルダー
        ZStack {
          Rectangle()
            .fill(themeManager.currentTheme.primaryColor.opacity(0.1))

          Image(systemName: "photo")
            .font(.title2)
            .foregroundColor(themeManager.currentTheme.primaryColor.opacity(0.6))
        }
      }
    }
    .scaledToFill()
    .frame(width: size, height: size)
    .clipped()
    .cornerRadius(cornerRadius)
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(themeManager.currentTheme.primaryColor.opacity(0.15), lineWidth: 1))
  }
}
