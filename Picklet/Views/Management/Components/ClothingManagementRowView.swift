import SDWebImageSwiftUI
import SwiftUI

struct ClothingManagementRowView: View {
  let clothing: Clothing
  let onDelete: () -> Void

  @EnvironmentObject private var viewModel: ClothingViewModel
  @EnvironmentObject private var themeManager: ThemeManager
  @EnvironmentObject private var referenceDataManager: ReferenceDataManager

  @State private var localImage: UIImage?

  private var imageUrl: String? {
    let imageSets = viewModel.imageSetsMap[clothing.id] ?? []
    return imageSets.first?.originalUrl
  }

  private var categoryNames: String {
    let categories = clothing.categoryIds.compactMap { id in
      referenceDataManager.categories.first(where: { $0.id == id })?.name
    }
    return categories.isEmpty ? "未分類" : categories.joined(separator: ", ")
  }

  var body: some View {
    HStack(spacing: 16) {
      // 洋服画像
      clothingImageView

      // 洋服情報
      VStack(alignment: .leading, spacing: 8) {
        // 名前
        Text(clothing.name)
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
          .lineLimit(2)

        // カテゴリ
        Text(categoryNames)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .lineLimit(1)

        // 着用回数
        Text("着用回数: \(clothing.wearCount)回")
          .font(.caption)
          .foregroundColor(themeManager.currentTheme.accentColor)
      }

      Spacer()

      // 削除ボタン
      Button(action: onDelete) {
        Image(systemName: "trash.circle.fill")
          .font(.title2)
          .foregroundColor(.red)
      }
      .buttonStyle(PlainButtonStyle())
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
    )
    .padding(.horizontal)
    .padding(.vertical, 4)
    .onAppear {
      loadImageIfNeeded()
    }
  }

  private var clothingImageView: some View {
    Group {
      if let urlString = imageUrl, let url = URL(string: urlString) {
        WebImage(url: url)
          .resizable()
          .indicator(.activity)
          .transition(.fade(duration: 0.5))
          .scaledToFill()
      } else if let image = localImage {
        Image(uiImage: image)
          .resizable()
          .scaledToFill()
      } else {
        Rectangle()
          .fill(Color(.systemGray5))
          .overlay(
            Image(systemName: "tshirt")
              .font(.title2)
              .foregroundColor(.secondary)
          )
      }
    }
    .frame(width: 60, height: 60)
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private func loadImageIfNeeded() {
    if imageUrl == nil {
      Task {
        if let image = viewModel.getImageForClothing(clothing.id) {
          await MainActor.run {
            localImage = image
          }
        }
      }
    }
  }
}
