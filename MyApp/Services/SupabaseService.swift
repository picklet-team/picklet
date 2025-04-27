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
    private let supabaseUrlString = "https://vlmwlvkaizgrcqzyonfy.supabase.co"
    static let shared = SupabaseService()

    private init() {}

    internal let client = SupabaseClient(
        supabaseURL: URL(string: "https://vlmwlvkaizgrcqzyonfy.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsbXdsdmthaXpncmNxenlvbmZ5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU1MDM0NzAsImV4cCI6MjA2MTA3OTQ3MH0.EymP7N-yMrCHVkBpzEG3sfBWckHjYxYkv9_DvOU6KCI"
    )

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

    var currentUser: User? {
        client.auth.currentUser
    }


    func fetchClothes() async throws -> [Clothing] {
        return try await client
            .from("clothes")
            .select("*")
            .execute()
            .decoded(to: [Clothing].self)
    }


    func addClothing(_ clothing: Clothing) async throws {
        _ = try await client
            .from("clothes")
            .insert(clothing)
            .execute()
    }


  
    func uploadImage(_ image: UIImage, for filename: String) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "画像の変換に失敗しました"])
        }

        let path = "\(filename).jpg"

        _ = try await client.storage
          .from("clothes-images")
          .upload(path, data: imageData, options: FileOptions(contentType: "image/jpeg"))
        print("🧑 Supabase currentUser =", SupabaseService.shared.currentUser?.id ?? "nil")

        // 公開URLを返す
        return "\(supabaseUrlString)/storage/v1/object/public/clothes-images/\(path)"
    }

    func deleteClothing(_ clothing: Clothing) async throws {
        _ = try await client
            .from("clothes")
            .delete()
            .eq("id", value: clothing.id)
            .execute()
    }

    func deleteClothingById(_ id: UUID) async throws {
        try await client
            .from("clothes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

  
    func fetchCachedWeather(for city: String) async throws -> Weather? {
        // 3時間前のISO8601文字列を作成
        let threeHoursAgo = Calendar.current.date(byAdding: .hour, value: -3, to: Date())!
        let formatter = ISO8601DateFormatter()
        let cutoff = formatter.string(from: threeHoursAgo)

        let response = try await client
            .from("weather_cache")
            .select("*")
            .eq("city", value: city)
            .gte("timestamp", value: cutoff)
            .limit(1)
            .order("timestamp", ascending: false)
            .execute()

        let results = try response.decoded(to: [Weather].self)
        return results.first
    }

    func updateClothing(_ clothing: Clothing, isNew: Bool) async throws {
        if isNew {
            print("🆕 insert開始: \(clothing)")
            _ = try await client
                .from("clothes")
                .insert([
                    "id": clothing.id.uuidString,
                    "user_id": clothing.user_id.uuidString,
                    "name": clothing.name,
                    "category": clothing.category,
                    "color": clothing.color,
                    "image_url": clothing.image_url,
                    "created_at": clothing.created_at
                ])
                .execute()
            print("✅ insert成功")
        } else {
            print("✏️ update開始: \(clothing)")
            _ = try await client
                .from("clothes")
                .update([
                    "name": clothing.name,
                    "category": clothing.category,
                    "color": clothing.color,
                    "image_url": clothing.image_url
                ])
                .eq("id", value: clothing.id)
                .execute()
            print("✅ update成功")
        }
    }
}
