//
//  SupabaseService.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

// Services/SupabaseService.swift
import SwiftUI
import Foundation
import Supabase
import PostgREST
import Storage
import UIKit


extension PostgrestResponse {
    func decoded<U: Decodable>(to type: U.Type) throws -> U {
        let decoder = JSONDecoder()
        return try decoder.decode(U.self, from: self.data)
    }
}

class SupabaseService {
    @AppStorage("isLoggedIn") var isLoggedIn = false
  
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    private let storageBucketName = "clothes-images"

    private init() {
        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String,
            let url = URL(string: urlString)
        else {
            fatalError("❌ Supabaseの設定がInfo.plistにありません")
        }

        self.client = SupabaseClient(supabaseURL: url, supabaseKey: key)
    }

    var currentUser: User? {
        client.auth.currentUser
    }

    // MARK: - 認証

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
        isLoggedIn = true
    }

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
        isLoggedIn = true
    }

    func signOut() async throws {
        try await client.auth.signOut()
        isLoggedIn = false
    }

    // MARK: - 服画像データ
  
    func fetchImages(for clothingId: UUID) async throws -> [ClothingImage] {
        return try await client
            .from("clothing_images")
            .select("*")
            .eq("clothing_id", value: clothingId.uuidString)
            .execute()
            .decoded(to: [ClothingImage].self)
    }

    func addImage(for clothingId: UUID, imageUrl: String) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
        }
        let clothingImage = [
            "id": UUID().uuidString,
            "clothing_id": clothingId.uuidString,
            "user_id": user.id.uuidString,
            "image_url": imageUrl,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]

        _ = try await client
            .from("clothing_images")
            .insert(clothingImage)
            .execute()
    }
  
    func uploadImage(_ image: UIImage, for filename: String) async throws -> String {
        // まずリサイズする（幅を最大800pxに制限）
        let resizedImage = image.resized(toMaxPixel: 800)

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw NSError(domain: "upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "画像の変換に失敗しました"])
        }

        let path = "\(filename).jpg"

        _ = try await client.storage
            .from(storageBucketName)
            .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))

        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            throw NSError(domain: "config", code: 0, userInfo: [NSLocalizedDescriptionKey: "Supabase URLが見つかりません"])
        }

        return "\(urlString)/storage/v1/object/public/\(storageBucketName)/\(path)"
    }

    // MARK: - 服データ

  
    func fetchClothes() async throws -> [Clothing] {
        return try await client
            .from("clothes")
            .select("*")
            .execute()
            .decoded(to: [Clothing].self)
    }

    func addClothing(_ clothing: Clothing) async throws {
        guard let user = currentUser else {
            throw NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"])
        }
        _ = try await client
            .from("clothes")
            .insert([
                "id": clothing.id.uuidString,
                "user_id": user.id.uuidString,
                "name": clothing.name,
                "category": clothing.category,
                "color": clothing.color,
                "created_at": clothing.created_at
            ])
            .execute()
    }

    func updateClothing(_ clothing: Clothing) async throws {
        _ = try await client
            .from("clothes")
            .update([
                "name": clothing.name,
                "category": clothing.category,
                "color": clothing.color
            ])
            .eq("id", value: clothing.id.uuidString)
            .execute()
    }

    func deleteClothing(_ clothing: Clothing) async throws {
        try await deleteClothingById(clothing.id)
    }

    func deleteClothingById(_ id: UUID) async throws {
        _ = try await client
            .from("clothes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - 天気キャッシュ

    func fetchWeatherCache(for city: String) async throws -> Weather {
        let today = DateFormatter.cachedDateFormatter.string(from: Date())

        let response = try await client
            .from("weather_cache")
            .select("*")
            .eq("city", value: city)
            .eq("date", value: today)
            .limit(1)
            .execute()

        return try response.decoded(to: Weather.self)
    }

    func insertWeatherCache(_ weather: Weather) async throws {
        _ = try await client
            .from("weather_cache")
            .insert(weather)
            .execute()
    }

}

extension DateFormatter {
    static let cachedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}

extension UIImage {
    func resized(toMaxPixel maxPixel: CGFloat) -> UIImage {
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if aspectRatio > 1 {
            // Landscape
            newSize = CGSize(width: maxPixel, height: maxPixel / aspectRatio)
        } else {
            // Portrait
            newSize = CGSize(width: maxPixel * aspectRatio, height: maxPixel)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage ?? self
    }
}
