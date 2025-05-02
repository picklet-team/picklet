import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothingItems: [Clothing] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]
  
  private let clothingService = SupabaseService.shared
  private let imageMetadataService = SupabaseService.shared
  private let imageStorageService = ImageStorageService.shared

  /// 服を保存（新規 or 更新）
  func updateClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) async {
    do {
      if isNew {
        try await clothingService.addClothing(clothing)
        print("✅ 新規服登録: \(clothing.name)")
      } else {
        try await clothingService.updateClothing(clothing)
        print("✅ 服更新: \(clothing.name)")
      }

      for set in imageSets {
        if set.isNew, let original = set.original {
          let originalUrl = try await imageStorageService.uploadImage(
            original, for: UUID().uuidString)
          try await imageMetadataService.addImage(for: clothing.id, originalUrl: originalUrl)
          print("✅ 画像アップロード & 登録完了: \(originalUrl)")
        }
      }
    } catch {
      print("❌ 服の保存エラー: \(error.localizedDescription)")
      self.errorMessage = error.localizedDescription
    }
  }

  /// すべての服と画像を読み込む（今は画像不要なら削除可）
  func loadClothes() async {
    isLoading = true
    do {
      clothingItems = try await clothingService.fetchClothes()
      print("✅ 服データ読み込み完了: \(clothingItems.count)件")

      for clothing in clothingItems {
        let images = try await imageMetadataService.fetchImages(for: clothing.id)
        let sets = images.map { img in
          EditableImageSet(
            id: img.id,
            original: nil,
            originalUrl: img.original_url,
            mask: nil,
            maskUrl: img.mask_url,
            result: nil,
            resultUrl: img.result_url,
            isNew: false
          )
        }
        imageSetsMap[clothing.id] = sets
      }

      print("✅ 画像データ読み込み完了")
    } catch {
      self.errorMessage = error.localizedDescription
    }
    isLoading = false
  }

  /// 服を削除
  func deleteClothing(_ clothing: Clothing) async {
    do {
      try await clothingService.deleteClothing(clothing)
      print("🗑️ 削除成功: \(clothing.name)")
      await loadClothes()
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }
}
