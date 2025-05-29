import SwiftUI

// MARK: - EditableImageSet Extension
extension EditableImageSet {
  var hasHighQuality: Bool {
    return original.size.width >= 100 && original.size.height >= 100
  }
}

// MARK: - Subviews
struct ImageListSection: View {
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
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

struct ClothingFormSection: View {
  @Binding var clothing: Clothing
  let canDelete: Bool
  let onDelete: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      VStack(alignment: .leading) {
        Text("服の情報")
          .font(.headline)
          .padding(.bottom, 4)

        VStack(spacing: 12) {
          TextField("カテゴリ", text: $clothing.category)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

          TextField("色", text: $clothing.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
      }
      .padding(.horizontal)
      .padding(.vertical, 8)

      if canDelete {
        deleteButton
      }
    }
  }

  private var deleteButton: some View {
    Section {
      Button(action: onDelete) {
        Text("削除")
          .font(.callout)
          .foregroundColor(.red.opacity(0.8))
      }
      .frame(maxWidth: .infinity, alignment: .center)
      .listRowBackground(Color.clear)
    }
    .textCase(nil)
  }
}
