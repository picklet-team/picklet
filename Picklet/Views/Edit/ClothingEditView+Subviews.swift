import SwiftUI

// MARK: - Array Extension for chunked method

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}

// MARK: - EditableImageSet Extension

extension EditableImageSet {
  var hasHighQuality: Bool {
    return original.size.width >= 100 && original.size.height >= 100
  }
}

// MARK: - Image Section Component

struct ImageListSection: View {
  @EnvironmentObject var themeManager: ThemeManager
  @Binding var imageSets: [EditableImageSet]
  let addAction: () -> Void
  let selectAction: (EditableImageSet) -> Void
  let isLoading: Bool

  var body: some View {
    VStack(alignment: .leading) {
      if isLoading {
        loadingIndicator
      }

      ClothingImageGalleryView(
        imageSets: $imageSets,
        showAddButton: true,
        onSelectImage: selectAction,
        onAddButtonTap: addAction)
    }
  }

  private var loadingIndicator: some View {
    HStack {
      Spacer()
      Text("高品質データを準備中...")
        .font(.caption)
        .foregroundColor(.secondary)
      ProgressView()
        .scaleEffect(0.7)
        .tint(themeManager.currentTheme.primaryColor)
      Spacer()
    }
    .padding(.vertical, 4)
  }
}
