import SDWebImageSwiftUI
import SwiftUI

// MARK: - Image Processing

extension ClothingEditView {
  /// バックグラウンドで画像の高品質バージョンを取得
  func enhanceImagesInBackground() {
    isBackgroundLoading = true

    Task(priority: .low) {
      defer { Task { await MainActor.run { isBackgroundLoading = false } } }

      // SQLiteManagerを使用
      let images = viewModel.dataManager.loadImageMetadata(for: clothing.id)
      let dataManager = viewModel.dataManager

      for image in images {
        await tryUpdateLowQualityImage(image, using: dataManager)
      }

      await MainActor.run {
        updateImageCache()
      }
    }
  }

  func tryUpdateLowQualityImage(_ image: ClothingImage, using dataManager: SQLiteManager) async {
    guard let idx = editingSets.firstIndex(where: { $0.id == image.id }) else { return }

    let currentSet = editingSets[idx]

    // 低品質画像のみ更新
    guard currentSet.original.size.width < 100 || currentSet.original.size.height < 100 else { return }
    guard let originalPath = image.originalLocalPath,
          let loadedImage = dataManager.loadImage(filename: originalPath)
    else { return }

    let updatedSet = createUpdatedImageSet(from: currentSet, with: loadedImage)

    await MainActor.run {
      if let stillIdx = editingSets.firstIndex(where: { $0.id == image.id }) {
        editingSets[stillIdx] = updatedSet
      }
    }
  }

  /// 特定の画像を高品質バージョンに確実に更新（マスク編集前など）
  func ensureHighQualityImage(for set: EditableImageSet, completion: @escaping (EditableImageSet) -> Void) {
    // すでに十分な品質があれば、そのままコールバック
    if set.hasHighQuality {
      completion(set)
      return
    }

    Task {
      // ローカルストレージからの取得を試みる
      if let updatedSet = await tryLoadImageFromLocal(set) {
        await MainActor.run { completion(updatedSet) }
        return
      }

      // ネットワークからの取得を試みる
      if let urlString = set.originalUrl, let url = URL(string: urlString) {
        loadImageFromNetwork(set: set, url: url, completion: completion)
      } else {
        await MainActor.run { completion(set) }
      }
    }
  }

  func tryLoadImageFromLocal(_ set: EditableImageSet) async -> EditableImageSet? {
    // localStorageService を dataManager に変更
    let images = viewModel.dataManager.loadImageMetadata(for: clothing.id)

    guard let image = images.first(where: { $0.id == set.id }),
          let originalPath = image.originalLocalPath,
          let loadedImage = viewModel.dataManager.loadImage(filename: originalPath)
    else {
      return nil
    }

    let updatedSet = createUpdatedImageSet(from: set, with: loadedImage)

    // 配列も更新
    await MainActor.run {
      if let idx = editingSets.firstIndex(where: { $0.id == set.id }) {
        editingSets[idx] = updatedSet
      }
    }

    return updatedSet
  }

  func loadImageFromNetwork(set: EditableImageSet, url: URL, completion: @escaping (EditableImageSet) -> Void) {
    let options: SDWebImageOptions = [.highPriority, .retryFailed, .refreshCached]

    SDWebImageManager.shared.loadImage(
      with: url,
      options: options,
      progress: nil) { image, _, _, _, _, _ in
        if let downloadedImage = image {
          let updatedSet = self.createUpdatedImageSet(from: set, with: downloadedImage)

          // localStorageService を dataManager に変更
          let filename = "\(set.id.uuidString)_original.jpg"
          if self.viewModel.dataManager.saveImage(downloadedImage, filename: filename) {
            print("💾 高品質画像をローカルに保存: \(filename)")
          }

          // 配列も更新
          if let idx = self.editingSets.firstIndex(where: { $0.id == set.id }) {
            DispatchQueue.main.async {
              self.editingSets[idx] = updatedSet
              completion(updatedSet)
            }
          } else {
            completion(updatedSet)
          }
        } else {
          completion(set) // 失敗したら元の画像を使用
        }
      }
  }

  func createUpdatedImageSet(from set: EditableImageSet, with newImage: UIImage) -> EditableImageSet {
    return EditableImageSet(
      id: set.id,
      original: newImage,
      originalUrl: set.originalUrl,
      mask: set.mask,
      maskUrl: set.maskUrl,
      result: set.result,
      resultUrl: set.resultUrl,
      isNew: set.isNew)
  }
}
