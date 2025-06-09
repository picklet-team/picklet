import Foundation
import SwiftUI

// MARK: - Image Management

extension ClothingViewModel {
  /// メインエントリーポイント - 服の保存（新規 or 更新）
  func saveClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) {
    print("📝 saveClothing 開始: ID=\(clothing.id), isNew=\(isNew)")

    isLoading = true

    // ステップ1: 衣類データを保存
    let success = if isNew {
      clothingService.addClothing(clothing)
    } else {
      clothingService.updateClothing(clothing)
    }

    if !success {
      errorMessage = "衣類データの保存に失敗しました"
      isLoading = false
      return
    }

    // ステップ2: ローカルストレージに画像を保存
    let localSavedSets = saveImagesToLocalStorage(clothing.id, imageSets: imageSets)

    // ステップ3: UIを更新
    updateLocalImagesCache(clothing.id, imageSets: localSavedSets)

    // ステップ4: UIの衣類リストを更新
    if let index = clothes.firstIndex(where: { $0.id == clothing.id }) {
      clothes[index] = clothing
    } else {
      clothes.append(clothing)
    }

    isLoading = false
    printDebugInfo()
  }

  /// 画像をローカルストレージに保存
  private func saveImagesToLocalStorage(_ clothingId: UUID, imageSets: [EditableImageSet]) -> [EditableImageSet] {
    print("💾 ローカルストレージへ画像を保存: clothingId=\(clothingId)")
    var updatedSets: [EditableImageSet] = []

    for var set in imageSets {
      // オリジナル画像を保存
      if set.original != UIImage(systemName: "photo") {
        if imageLoaderService.saveImage(set.original, for: clothingId, imageId: set.id) {
          print("✅ オリジナル画像をローカルに保存: \(set.id)")
          set.isNew = false
        }
      }

      // マスク画像があれば保存
      if let mask = set.mask {
        let maskFilename = "\(set.id.uuidString)_mask.jpg"
        if dataManager.saveImage(mask, filename: maskFilename) {
          print("✅ マスク画像をローカルに保存: \(maskFilename)")

          // メタデータを更新
          var metadata = dataManager.loadImageMetadata(for: clothingId)
          if let index = metadata.firstIndex(where: { $0.id == set.id }) {
            metadata[index] = metadata[index].updatingLocalPath(maskLocalPath: maskFilename)
            dataManager.saveImageMetadata(metadata, for: clothingId)
          }
        }
      }

      // AIマスク画像があれば保存
      if let aimask = set.aimask {
        let aimaskFilename = "\(set.id.uuidString)_aimask.jpg"
        if dataManager.saveImage(aimask, filename: aimaskFilename) {
          print("✅ AIマスク画像をローカルに保存: \(aimaskFilename)")
        }
      }

      updatedSets.append(set)
    }

    return updatedSets
  }

  /// UIの即時更新のためにメモリ内の画像キャッシュを更新
  public func updateLocalImagesCache(_ clothingId: UUID, imageSets: [EditableImageSet]) {
    imageSetsMap[clothingId] = imageSets
    print("✅ 即時表示用に画像キャッシュ更新: \(clothingId)")
  }

  /// 全ての服に関連する画像を読み込む
  func loadAllImages() async {
    print("🖼️ loadAllImages 開始")
    var newMap: [UUID: [EditableImageSet]] = [:]

    let placeholderImage = UIImage(systemName: "photo") ?? UIImage()

    for clothing in clothes {
      let images = dataManager.loadImageMetadata(for: clothing.id)
      print("📷 \(clothing.id)の画像メタデータを取得: \(images.count)件")

      var imageSets: [EditableImageSet] = []

      for image in images {
        var original: UIImage = placeholderImage
        let aimask: UIImage? = nil
        var mask: UIImage?

        // オリジナル画像を読み込む
        if let originalPath = image.originalLocalPath {
          if let loadedImage = dataManager.loadImage(filename: originalPath) {
            original = loadedImage
            print("✅ ローカルからオリジナル画像を読み込み: \(originalPath)")
          }
        }

        // マスク画像を読み込む
        if let maskPath = image.maskLocalPath {
          if let loadedMask = dataManager.loadImage(filename: maskPath) {
            mask = loadedMask
            print("✅ ローカルからマスク画像を読み込み: \(maskPath)")
          }
        }

        let set = EditableImageSet(
          id: image.id,
          original: original,
          aimask: aimask,
          mask: mask,
          isNew: false)

        imageSets.append(set)
      }

      newMap[clothing.id] = imageSets
    }

    imageSetsMap = newMap
    print("✅ 全画像読み込み完了: \(newMap.count)アイテム")
  }

  /// 服IDから画像を読み込むメソッド（ビュー層からの呼び出し用）
  func getImageForClothing(_ clothingId: UUID) -> UIImage? {
    if let imageSets = imageSetsMap[clothingId], let firstSet = imageSets.first {
      if firstSet.original != UIImage(systemName: "photo") {
        return firstSet.original
      }
    }

    return imageLoaderService.loadFirstImageForClothing(clothingId)
  }

  /// 新規衣類追加（データベースに保存）
  func addClothing(_ clothing: Clothing, imageSets: [EditableImageSet] = []) {
    saveClothing(clothing, imageSets: imageSets, isNew: true)
  }

  /// 既存衣類更新（データベースに保存）
  func updateClothing(_ clothing: Clothing, imageSets: [EditableImageSet] = []) {
    saveClothing(clothing, imageSets: imageSets, isNew: false)
  }

  /// 画像セットを削除（データベースからも削除）
  func deleteImageSet(_ imageSetId: UUID, from clothingId: UUID) {
    print("🗑️ ViewModelで画像削除処理開始: \(imageSetId)")

    // 1. メモリキャッシュから削除
    if var imageSets = imageSetsMap[clothingId] {
      imageSets.removeAll { $0.id == imageSetId }
      imageSetsMap[clothingId] = imageSets
    }

    // 2. データベースから削除
    let imageMetadata = dataManager.loadImageMetadata(for: clothingId)

    if let targetImage = imageMetadata.first(where: { $0.id == imageSetId }) {
      // 画像ファイルを削除
      if let originalPath = targetImage.originalLocalPath {
        _ = dataManager.deleteImage(filename: originalPath)
      }

      if let maskPath = targetImage.maskLocalPath {
        _ = dataManager.deleteImage(filename: maskPath)
      }

      // メタデータから削除して保存
      let updatedMetadata = imageMetadata.filter { $0.id != imageSetId }
      dataManager.saveImageMetadata(updatedMetadata, for: clothingId)
    }

    print("✅ ViewModelで画像セット削除完了: \(imageSetId)")
  }
}
