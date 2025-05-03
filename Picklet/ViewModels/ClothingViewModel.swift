import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothes: [Clothing] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]
  
  private let clothingService = SupabaseService.shared
  private let imageMetadataService = ImageMetadataService.shared
//  private let imageStorageService = ImageStorageService.shared
  private let originalImageStorageService = ImageStorageService(bucketName: "originals")
  private let maskImageStorageService = ImageStorageService(bucketName: "masks")

  /// 服を保存（新規 or 更新）
  func updateClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) async {
    do {
      if isNew {
        try await clothingService.addClothing(clothing)
      } else {
        try await clothingService.updateClothing(clothing)
      }

      for idx in imageSets.indices {
        var set = imageSets[idx]
        if set.isNew, set.originalUrl == nil {
          let url = try await originalImageStorageService.uploadImage(set.original, for: set.id.uuidString)
          try await imageMetadataService.addImage(for: clothing.id, originalUrl: url)
          set.originalUrl = url
          set.isNew = false
        }

        if let mask = set.mask, set.maskUrl == nil {
          let maskUrl = try await maskImageStorageService.uploadImage(mask, for: set.id.uuidString)
          try await imageMetadataService.updateImageMask(imageId: set.id, maskUrl: maskUrl)
          set.maskUrl = maskUrl
        }
      }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  /// 起動時 or 手動で呼び出す「差分だけ同期」メソッド
  func syncIfNeeded() async {
    do {
      // 1) サーバーから最新リストを取得
      let remote = try await clothingService.fetchClothes()
      // 2) 差分検出＆マージ
      var merged = clothes   // 現在のローカル配列をコピー
      for item in remote {
        if let idx = merged.firstIndex(where: { $0.id == item.id }) {
          // ローカルの方が古ければ置き換え
          if merged[idx].updatedAt < item.updatedAt {
            merged[idx] = item
          }
        } else {
          // ローカルにない新規は追加
          merged.append(item)
        }
      }
      // 3) ローカルにしかないサーバー削除済アイテムは optional で後処理してもOK
      self.clothes = merged
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  /// 服を削除
  func deleteClothing(_ clothing: Clothing) async {
    do {
      try await clothingService.deleteClothing(clothing)
      // １）ローカル配列から該当アイテムを取り除く
      if let idx = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes.remove(at: idx)
      }
      // ２）マップからも削除
      imageSetsMap.removeValue(forKey: clothing.id)
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }
}
