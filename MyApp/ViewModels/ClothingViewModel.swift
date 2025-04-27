import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
    @Published var clothes: [Clothing] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var clothingImages: [UUID: [ClothingImage]] = [:]

    func updateClothing(_ clothing: Clothing, isNew: Bool) async {
        do {
            if isNew {
                try await SupabaseService.shared.addClothing(clothing)
            } else {
                try await SupabaseService.shared.updateClothing(clothing)
            }
            
            if let images = clothingImages[clothing.id] {
                for image in images {
                    try await SupabaseService.shared.addImage(for: clothing.id, imageUrl: image.image_url)
                }
            }
        } catch {
            print("❌ 服の更新エラー: \(error.localizedDescription)")
        }
    }
  
    func loadClothes() async {
        isLoading = true
        do {
            clothes = try await SupabaseService.shared.fetchClothes()
            for clothing in clothes {
                let images = try await SupabaseService.shared.fetchImages(for: clothing.id)
                clothingImages[clothing.id] = images
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func deleteClothing(_ clothing: Clothing) async {
        do {
            try await SupabaseService.shared.deleteClothing(clothing)
            await loadClothes()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
