//
//
//

import Foundation
import PostgREST
import Supabase

class ImageMetadataService {
    static let shared = ImageMetadataService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = AuthService.shared.client
    }
    
    func fetchImages(for clothingId: UUID) async throws -> [ClothingImage] {
        return
            try await client
            .from("clothing_images")
            .select("*")
            .eq("clothing_id", value: clothingId.uuidString)
            .execute()
            .decoded(to: [ClothingImage].self)
    }
    
    func addImage(
        for clothingId: UUID, originalUrl: String, maskUrl: String? = nil, resultUrl: String? = nil
    ) async throws {
        guard let user = AuthService.shared.currentUser else {
            throw NSError(
                domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
        }
        
        let newImage = NewClothingImage(
            id: UUID(),
            clothing_id: clothingId,
            user_id: user.id,
            original_url: originalUrl,
            mask_url: maskUrl,
            result_url: resultUrl,
            created_at: ISO8601DateFormatter().string(from: Date())
        )
        
        _ =
            try await client
            .from("clothing_images")
            .insert(newImage)
            .execute()
    }
    
    func updateImageMaskAndResult(id: UUID, maskUrl: String?, resultUrl: String?) async throws {
        _ =
            try await client
            .from("clothing_images")
            .update([
                "mask_url": maskUrl,
                "result_url": resultUrl,
            ])
            .eq("id", value: id.uuidString)
            .execute()
    }
}

private struct NewClothingImage: Encodable {
    let id: UUID
    let clothing_id: UUID
    let user_id: UUID
    let original_url: String
    let mask_url: String?
    let result_url: String?
    let created_at: String
}
