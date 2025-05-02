//
//  SupabaseService.swift
//
//  Created by al dente on 2025/04/25.
//

import Foundation
import Supabase
import SwiftUI
import UIKit

class SupabaseService {
  static let shared = SupabaseService()
  
  private init() {}
  
  // MARK: - Auth Service Delegation
  
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
  
  // MARK: - Clothing Data Service Delegation
  
  func fetchClothes() async throws -> [Clothing] {
    return try await ClothingDataService.shared.fetchClothes()
  }
  
  func addClothing(_ clothing: Clothing) async throws {
    try await ClothingDataService.shared.addClothing(clothing)
  }
  
  func updateClothing(_ clothing: Clothing) async throws {
    try await ClothingDataService.shared.updateClothing(clothing)
  }
  
  func deleteClothing(_ clothing: Clothing) async throws {
    try await ClothingDataService.shared.deleteClothing(clothing)
  }
  
  func deleteClothingById(_ id: UUID) async throws {
    try await ClothingDataService.shared.deleteClothingById(id)
  }
  
  // MARK: - Image Storage Service Delegation
  
  func fetchImages(for clothingId: UUID) async throws -> [ClothingImage] {
    return try await ImageStorageService.shared.fetchImages(for: clothingId)
  }
  
  func addImage(
    for clothingId: UUID, originalUrl: String, maskUrl: String? = nil, resultUrl: String? = nil
  ) async throws {
    try await ImageStorageService.shared.addImage(
      for: clothingId, originalUrl: originalUrl, maskUrl: maskUrl, resultUrl: resultUrl)
  }
  
  func updateImageMaskAndResult(id: UUID, maskUrl: String?, resultUrl: String?) async throws {
    try await ImageStorageService.shared.updateImageMaskAndResult(id: id, maskUrl: maskUrl, resultUrl: resultUrl)
  }
  
  func uploadImage(_ image: UIImage, for filename: String) async throws -> String {
    return try await ImageStorageService.shared.uploadImage(image, for: filename)
  }
  
  func listClothingImageURLs() async throws -> [URL] {
    return try await ImageStorageService.shared.listClothingImageURLs()
  }
  
  // MARK: - Weather Cache Service Delegation
  
  func fetchWeatherCache(for city: String) async throws -> Weather {
    return try await WeatherCacheService.shared.fetchWeatherCache(for: city)
  }
  
  func insertWeatherCache(_ weather: Weather) async throws {
    try await WeatherCacheService.shared.insertWeatherCache(weather)
  }
}
