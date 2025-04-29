import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
    @Published var clothes: [Clothing] = []
    @Published var isLoading = false
    @Published var error: String?

    @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]

    /// 服を保存（新規 or 更新）
    func updateClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) async {
        do {
            if isNew {
                try await SupabaseService.shared.addClothing(clothing)
                print("✅ 新規服登録: \(clothing.name)")
            } else {
                try await SupabaseService.shared.updateClothing(clothing)
                print("✅ 服更新: \(clothing.name)")
            }

            for set in imageSets {
                if set.isNew, let original = set.original {
                    let originalUrl = try await SupabaseService.shared.uploadImage(original, for: UUID().uuidString)
                    try await SupabaseService.shared.addImage(for: clothing.id, originalUrl: originalUrl)
                    print("✅ 画像アップロード & 登録完了: \(originalUrl)")
                }
            }
        } catch {
            print("❌ 服の保存エラー: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
    }
  
    /// すべての服と画像を読み込む（今は画像不要なら削除可）
    func loadClothes() async {
        isLoading = true
        do {
            clothes = try await SupabaseService.shared.fetchClothes()
            print("✅ 服データ読み込み完了: \(clothes.count)件")

            for clothing in clothes {
                let images = try await SupabaseService.shared.fetchImages(for: clothing.id)
                let sets = images.map { img in
                    EditableImageSet(
                        id: img.id,
                        original: nil,
                        originalUrl: img.original_url,
                        mask: nil,
                        maskUrl: nil,
                        result: nil,
                        resultUrl: nil,
                        isNew: false
                    )
                }
                imageSetsMap[clothing.id] = sets
            }

            print("✅ 画像データ読み込み完了")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }


    /// 服を削除
    func deleteClothing(_ clothing: Clothing) async {
        do {
            try await SupabaseService.shared.deleteClothing(clothing)
            print("🗑️ 削除成功: \(clothing.name)")
            await loadClothes()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
