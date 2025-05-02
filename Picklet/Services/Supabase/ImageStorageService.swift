//
//
//

import Foundation
import PostgREST
import Storage
import Supabase
import UIKit

class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let client: SupabaseClient
    private let storageBucketName = "clothes-images"
    
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
    
    func uploadImage(_ image: UIImage, for filename: String) async throws -> String {
        let resizedImage = image.resized(toMaxPixel: 800)
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw NSError(
                domain: "upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "画像の変換に失敗しました"])
        }
        
        let path = "\(filename).jpg"
        
        _ = try await client.storage
            .from(storageBucketName)
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            throw NSError(
                domain: "config", code: 0, userInfo: [NSLocalizedDescriptionKey: "Supabase URLが見つかりません"])
        }
        
        return "\(urlString)/storage/v1/object/public/\(storageBucketName)/\(path)"
    }
    
    func listClothingImageURLs() async throws -> [URL] {
        guard let userId = AuthService.shared.currentUser?.id.uuidString else {
            throw NSError(
                domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
        }
        
        let bucket = client.storage.from(storageBucketName)
        let objects = try await bucket.list(path: userId)
        
        guard let baseURLString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
        else {
            throw NSError(
                domain: "config", code: 0, userInfo: [NSLocalizedDescriptionKey: "Supabase URLが見つかりません"])
        }
        
        let urls = objects.map { object in
            URL(
                string:
                    "\(baseURLString)/storage/v1/object/public/\(storageBucketName)/\(userId)/\(object.name)")
        }
        
        return urls.compactMap { $0 }
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
