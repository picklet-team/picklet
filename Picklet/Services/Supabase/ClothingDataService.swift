//
//
//

import Foundation
import PostgREST
import Supabase

class ClothingDataService {
    static let shared = ClothingDataService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = AuthService.shared.client
    }
    
    func fetchClothes() async throws -> [Clothing] {
        return
            try await client
            .from("clothes")
            .select("*")
            .execute()
            .decoded(to: [Clothing].self)
    }
    
    func addClothing(_ clothing: Clothing) async throws {
        guard let user = AuthService.shared.currentUser else {
            throw NSError(
                domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
        }
        _ =
            try await client
            .from("clothes")
            .insert([
                "id": clothing.id.uuidString,
                "user_id": user.id.uuidString,
                "name": clothing.name,
                "category": clothing.category,
                "color": clothing.color,
                "created_at": clothing.created_at,
            ])
            .execute()
    }
    
    func updateClothing(_ clothing: Clothing) async throws {
        _ =
            try await client
            .from("clothes")
            .update([
                "name": clothing.name,
                "category": clothing.category,
                "color": clothing.color,
            ])
            .eq("id", value: clothing.id.uuidString)
            .execute()
    }
    
    func deleteClothing(_ clothing: Clothing) async throws {
        try await deleteClothingById(clothing.id)
    }
    
    func deleteClothingById(_ id: UUID) async throws {
        _ =
            try await client
            .from("clothes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
