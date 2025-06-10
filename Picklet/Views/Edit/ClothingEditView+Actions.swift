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

  func deleteImageSet(_ imageSetId: UUID) {
    print("🗑️ 画像削除処理開始: \(imageSetId)")

    // 1. メモリ上の配列から削除
    editingSets.removeAll { $0.id == imageSetId }

    // 2. 選択中の画像セットをクリア
    if selectedImageSet?.id == imageSetId {
      selectedImageSet = nil
    }

    // 3. データベースから画像ファイルとメタデータを削除
    let dataManager = SQLiteManager.shared

    // 画像メタデータを取得
    let imageMetadata = dataManager.loadImageMetadata(for: editingClothing.id)

    // 削除対象の画像メタデータを見つける
    if let targetImage = imageMetadata.first(where: { $0.id == imageSetId }) {
      // 画像ファイルを削除
      if let originalPath = targetImage.originalLocalPath {
        _ = dataManager.deleteImage(filename: originalPath)
        print("🗑️ オリジナル画像ファイルを削除: \(originalPath)")
      }

      if let maskPath = targetImage.maskLocalPath {
        _ = dataManager.deleteImage(filename: maskPath)
        print("🗑️ マスク画像ファイルを削除: \(maskPath)")
      }

      // メタデータから削除して保存
      let updatedMetadata = imageMetadata.filter { $0.id != imageSetId }
      dataManager.saveImageMetadata(updatedMetadata, for: editingClothing.id)
      print("🗑️ 画像メタデータを更新")
    }

    // 4. ViewModelのキャッシュを更新
    updateImageCache()

    print("✅ 画像セットを完全に削除しました: \(imageSetId)")
  }

  // 既存のメソッドがある場合はここで実装（重複を避ける）
  // enhanceImagesInBackground() と ensureHighQualityImage(for:completion:) は
  // 既に別の場所で定義されている場合は削除
}
