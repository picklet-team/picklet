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

  internal let client: SupabaseClient
  private let storageBucketName = "clothes-images"
  
  private let imageStorageService = ImageStorageService.shared
  
  // private let authService = AuthService.shared
  // private let clothingDataService = ClothingDataService.shared
  // private let imageMetadataService = ImageMetadataService.shared
  // private let weatherFetchService = WeatherFetchService.shared
  // private let weatherCacheService = WeatherCacheService.shared

  private init() {
    self.client = AuthService.shared.client
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

  // MARK: - 服画像データ

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
    guard let user = currentUser else {
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
    return try await ImageStorageService.shared.uploadImage(image, for: filename)
  }

  func listClothingImageURLs() async throws -> [URL] {
    return try await ImageStorageService.shared.listClothingImageURLs()
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



private struct NewClothingImage: Encodable {
  let id: UUID
  let clothing_id: UUID
  let user_id: UUID
  let original_url: String
  let mask_url: String?
  let result_url: String?
  let created_at: String
}
