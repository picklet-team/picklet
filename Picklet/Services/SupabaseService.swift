//
//  SupabaseService.swift
//
//  Created by al dente on 2025/04/25.
//

import Foundation
import PostgREST
import Storage
import Supabase
import SwiftUI
import UIKit

class SupabaseService {
  static let shared = SupabaseService()

  let client: SupabaseClient

  private init() {
    client = AuthService.shared.client
  }

  // MARK: - 認証

  var isLoggedIn: Bool {
    get { AuthService.shared.isLoggedIn }
    set { AuthService.shared.isLoggedIn = newValue }
  }

  var currentUser: User? {
    AuthService.shared.currentUser
  }

  func signIn(email: String, password: String) async throws {
    try await AuthService.shared.signIn(email: email, password: password)
  }

  func signUp(email: String, password: String) async throws {
    try await AuthService.shared.signUp(email: email, password: password)
  }

  func signOut() async throws {
    try await AuthService.shared.signOut()
  }

  // MARK: - 服データ

  func fetchClothes() async throws -> [Clothing] {
    return
      try await client
        .from("clothes")
        .select("*")
        .execute()
        .decoded(to: [Clothing].self)
  }

  func addClothing(_ clothing: Clothing) async throws {
    guard let user = currentUser else {
      throw NSError(
        domain: "auth",
        code: 401,
        userInfo: [NSLocalizedDescriptionKey: "ユーザーが未ログインです"]
      )
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
          "created_at": clothing.createdAt,
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

  // MARK: - 天気キャッシュ

  func fetchWeatherCache(for city: String) async throws -> Weather {
    let today = DateFormatter.cachedDateFormatter.string(from: Date())

    let response =
      try await client
        .from("weather_cache")
        .select("*")
        .eq("city", value: city)
        .eq("date", value: today)
        .limit(1)
        .execute()

    return try response.decoded(to: Weather.self)
  }

  func insertWeatherCache(_ weather: Weather) async throws {
    _ =
      try await client
        .from("weather_cache")
        .insert(weather)
        .execute()
  }
}

// NewClothingImage 構造体は Helpers/NewClothingImage.swift に移動したため削除
