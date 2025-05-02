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

func getOpenWeatherApiKey() -> String {
    guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String else {
        fatalError("❌ OpenWeather APIキーがInfo.plistにありません")
    }
    return apiKey
}

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
  
  func fetchWeather(for city: String) async throws -> Weather {
    do {
      return try await fetchCachedWeather(for: city)
    } catch {
      let weather = try await WeatherAPIService.shared.fetchWeatherData(for: city)
      try await saveWeatherToCache(weather)
      return weather
    }
  }

  // キャッシュ取得
  func fetchCachedWeather(for city: String) async throws -> Weather {
    return try await WeatherFetchService.shared.fetchWeatherCache(for: city)
  }

  // Supabaseに保存
  func saveWeatherToCache(_ weather: Weather) async throws {
    try await WeatherCacheService.shared.insertWeatherCache(weather)
  }
}
