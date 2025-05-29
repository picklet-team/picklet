import SwiftUI

// MARK: - Action Handlers
extension ClothingEditView {

  func setupInitialData() {
    editingSets = viewModel.imageSetsMap[clothing.id] ?? []

    if !isNew && !editingSets.isEmpty {
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
    viewModel.updateLocalImagesCache(clothing.id, imageSets: editingSets)
  }

  func saveChanges() {
    Task {
      viewModel.saveClothing(clothing, imageSets: editingSets, isNew: isNew)
      dismiss()
    }
  }

  func deleteClothing() async {
    viewModel.deleteClothing(clothing)
    dismiss()
  }
}
