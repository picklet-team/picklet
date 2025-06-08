import SwiftUI

// MARK: - Action Handlers

extension ClothingEditView {
  func setupInitialData() {
    editingSets = viewModel.imageSetsMap[clothing.id] ?? []

    if !isNew, !editingSets.isEmpty {
      enhanceImagesInBackground()
    }

    if openPhotoPickerOnAppear {
      showPhotoPicker = true
    }
  }

  func prepareImageForEditing(_ set: EditableImageSet) {
    if !set.isNew {
      ensureHighQualityImage(for: set) { updatedSet in
        selectedImageSet = updatedSet
      }
    } else {
      selectedImageSet = set
    }
  }

  func addNewImageSet(_ image: UIImage) {
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
    updateImageCache()
  }

  func updateImageCache() {
    viewModel.updateLocalImagesCache(editingClothing.id, imageSets: editingSets)
  }

  func saveChanges() {
    // 保存時にのみ元のClothingデータを更新
    clothing = editingClothing

    Task {
      viewModel.saveClothing(clothing, imageSets: editingSets, isNew: isNew)
      dismiss()
    }
  }

  func deleteClothing() async {
    viewModel.deleteClothing(clothing)
    dismiss()
  }

  // 既存のメソッドがある場合はここで実装（重複を避ける）
  // enhanceImagesInBackground() と ensureHighQualityImage(for:completion:) は
  // 既に別の場所で定義されている場合は削除
}
