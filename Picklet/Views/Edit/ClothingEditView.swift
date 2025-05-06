import SDWebImageSwiftUI
import SwiftUI

struct ClothingEditView: View {
  @EnvironmentObject private var viewModel: ClothingViewModel
  @Environment(\.dismiss) private var dismiss
  @Binding var clothing: Clothing
  let openPhotoPickerOnAppear: Bool
  let canDelete: Bool
  let isNew: Bool

  @State private var editingSets: [EditableImageSet] = []
  @State private var selectedImageSet: EditableImageSet?
  @State private var showPhotoPicker = false
  @State private var showImageEditor = false
  @State private var showDeleteConfirm = false

  var body: some View {
    VStack {
      ImageListSection(
        imageSets: $editingSets,
        addAction: { showPhotoPicker = true },
        selectAction: { set in
          selectedImageSet = set
          showImageEditor = true
        })

      ClothingFormSection(clothing: $clothing)

      Spacer()

      ActionButtonsSection(
        saveAction: saveChanges,
        deleteAction: { showDeleteConfirm = true },
        canDelete: canDelete)
    }
    .navigationTitle("服を編集")
    .onAppear {
      // 初期ロード
      if editingSets.isEmpty {
        editingSets = viewModel.imageSetsMap[clothing.id] ?? []
      }
      if openPhotoPickerOnAppear {
        showPhotoPicker = true
      }
    }
    .sheet(isPresented: $showPhotoPicker) {
      CaptureOrLibraryView { image in
        let newSet = EditableImageSet(
          id: UUID(),
          original: image.normalized(),
          originalUrl: nil,
          mask: nil,
          maskUrl: nil,
          result: nil,
          resultUrl: nil,
          isNew: true)
        editingSets.append(newSet)

        // 画像選択後、即座にViewModelのキャッシュも更新
        viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
        print("📸 画像選択後にimageSetsMapを更新: \(clothing.id), 画像数: \(editingSets.count)")
      }
    }
    .sheet(item: $selectedImageSet) { imageSet in
      MaskEditorView(imageSet: bindingFor(imageSet))
        .onDisappear {
          // マスク編集後も即座にキャッシュを更新
          viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
          print("🎭 マスク編集後にimageSetsMapを更新: \(clothing.id)")
        }
    }
    .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
      Button("削除する", role: .destructive) {
        Task {
          await viewModel.deleteClothing(clothing)
          dismiss()
        }
      }
      Button("キャンセル", role: .cancel) {}
    }
  }

  // MARK: - Actions

  private func saveChanges() {
    Task {
      await viewModel.saveClothing(
        clothing,
        imageSets: editingSets,
        isNew: isNew)
      dismiss()
    }
  }

  private func bindingFor(_ set: EditableImageSet) -> Binding<EditableImageSet> {
    guard let idx = editingSets.firstIndex(where: { $0.id == set.id }) else {
      fatalError("Invalid imageSet")
    }
    return $editingSets[idx]
  }
}

// MARK: - Subviews

private struct ImageListSection: View {
  @Binding var imageSets: [EditableImageSet]
  let addAction: () -> Void
  let selectAction: (EditableImageSet) -> Void

  var body: some View {
    VStack(alignment: .leading) {
      // バインディング対応の共通コンポーネントを使用
      ClothingImageGalleryView(
        imageSets: $imageSets, // $を使ってバインディングを渡す
        showAddButton: true,
        onSelectImage: selectAction,
        onAddButtonTap: addAction)
    }
  }
}

private struct ClothingFormSection: View {
  @Binding var clothing: Clothing

  var body: some View {
    Form {
      Section(header: Text("服の情報")) {
        TextField("名前", text: $clothing.name)
        TextField("カテゴリ", text: $clothing.category)
        TextField("色", text: $clothing.color)
      }
    }
  }
}

private struct ActionButtonsSection: View {
  let saveAction: () -> Void
  let deleteAction: () -> Void
  let canDelete: Bool

  var body: some View {
    HStack {
      if canDelete {
        Button(action: deleteAction) {
          Text("削除")
            .foregroundColor(.red)
        }
        Spacer()
      }
      Button(action: saveAction) {
        Text("保存")
          .bold()
      }
    }
    .padding()
  }
}
