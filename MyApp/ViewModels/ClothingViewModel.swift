import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
    @Published var clothes: [Clothing] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadClothes() async {
        isLoading = true
        do {
            clothes = try await SupabaseService.shared.fetchClothes()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
  
    func createLocalTemporaryClothing() async throws -> Clothing {
        guard let user = SupabaseService.shared.currentUser else {
            throw NSError(domain: "User not found", code: 0)
        }
        let tempClothing = Clothing(
            id: UUID(),
            user_id: user.id,
            name: "",
            category: "",
            color: "",
            image_url: "",
            created_at: ISO8601DateFormatter().string(from: Date())
        )

        clothes.append(tempClothing)
        return tempClothing
    }

      
  
    func addTemporaryClothingAndReturn() async throws -> Clothing {
        guard let user = SupabaseService.shared.currentUser else {
            throw NSError(domain: "User not found", code: 0)
        }

        let clothing = Clothing(
            id: UUID(),
            user_id: user.id,
            name: "",
            category: "tops",
            color: "",
            image_url: "",
            created_at: ISO8601DateFormatter().string(from: Date())
        )

        try await SupabaseService.shared.addClothing(clothing)
        return clothing
    }

    func updateTemporaryClothing(with imageUrl: String) async -> Clothing? {
        guard var latest = clothes.last else { return nil }
        latest.image_url = imageUrl

        do {
            try await SupabaseService.shared.updateClothing(latest, isNew: false)
            await loadClothes()
            return latest
        } catch {
            print("❌ 仮登録更新失敗: \(error.localizedDescription)")
            return nil
        }
    }

    func deleteClothingById(_ id: UUID) async {
        do {
            try await SupabaseService.shared.deleteClothingById(id)
            await loadClothes()
        } catch {
            print("❌ 仮登録削除失敗: \(error.localizedDescription)")
        }
    }

    func updateClothing(_ clothing: Clothing, isNew: Bool) async {
        do {
            try await SupabaseService.shared.updateClothing(clothing, isNew: isNew)
            await loadClothes()
        } catch {
            print("❌ updateClothing失敗: \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
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
