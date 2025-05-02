//
//  WeatherService.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

// WeatherService.swift

import CoreLocation
import Foundation
import Supabase

let openWeatherApiKey = "a27cc85d4f34ac0e5e5f4fde84d5067f"

struct OpenWeatherResponse: Codable {
  struct WeatherItem: Codable {
    let description: String
    let icon: String
  }
  struct Main: Codable {
    let temp: Double
  }
  let weather: [WeatherItem]
  let main: Main
}

class WeatherManager {

  static let shared = WeatherManager()

  // キャッシュ取得
  func fetchCachedWeather(for city: String) async throws -> Weather {
    return try await SupabaseService.shared.fetchWeatherCache(for: city)
  }

  // Supabaseに保存
  func saveWeatherToCache(_ weather: Weather) async throws {
    try await SupabaseService.shared.insertWeatherCache(weather)
  }
}

class WeatherService {
  var cachedWeather: Weather?
  
  func getCurrentWeather(forCity city: String) async -> Weather? {
    if let cached = cachedWeather, cached.city == city {
      return cached
    }
    
    do {
      return try await WeatherManager.shared.fetchCachedWeather(for: city)
    } catch {
      return nil
    }
  }
  
  func saveWeather(_ weather: Weather) async throws {
    try await WeatherManager.shared.saveWeatherToCache(weather)
    cachedWeather = weather
  }
}
