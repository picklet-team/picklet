//
//
//

import Foundation
import Storage
import Supabase
import UIKit

@_implementationOnly import class Picklet.SupabaseService

class ImageStorageService {
    static let shared = ImageStorageService()
    
    private let client: SupabaseClient
    private let storageBucketName = "clothes-images"
    
    private init() {
        self.client = SupabaseService.shared.client
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
        guard let userId = SupabaseService.shared.currentUser?.id.uuidString else {
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
