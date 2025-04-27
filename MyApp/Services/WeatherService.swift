//
//  WeatherService.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

// WeatherService.swift
// 天気情報取得 + キャッシュ管理

import Foundation
import CoreLocation
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
    private init() {}

    private let supabase = SupabaseService.shared

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private let isoFormatter = ISO8601DateFormatter()

    // キャッシュ取得（当日のみ）
    func fetchCachedWeather(for city: String) async throws -> Weather {
        let today = dateFormatter.string(from: Date())

        let response = try await supabase.client
            .from("weather_cache")
            .select("*")
            .eq("city", value: city)
            .eq("date", value: today)
            .limit(1)
            .execute()

        return try response.decoded(to: Weather.self)
    }

    // APIから取得
    func fetchWeatherFromAPI(for city: String) async throws -> Weather {
        let cityEncoded = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(cityEncoded)&appid=\(openWeatherApiKey)&units=metric&lang=ja")!

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)

        let now = Date()

        return Weather(
            city: city,
            date: dateFormatter.string(from: now),
            temperature: decoded.main.temp,
            condition: decoded.weather.first?.description ?? "不明",
            icon: decoded.weather.first?.icon ?? "",
            updated_at: isoFormatter.string(from: now)
        )
    }

    // Supabaseに保存
    func saveWeatherToCache(_ weather: Weather) async throws {
        _ = try await supabase.client
            .from("weather_cache")
            .insert(weather)
            .execute()
    }

    // 天気情報の取得（キャッシュ優先）
    func getWeather(for city: String) async throws -> Weather {
        // 1. Supabaseキャッシュ確認
        if let cached = try? await fetchCachedWeather(for: city) {
            print("🌤 キャッシュヒット: \(city)")
            return cached
        }

        // 2. APIから取得
        let fresh = try await fetchWeatherFromAPI(for: city)

        // 3. Supabaseに保存
        try await saveWeatherToCache(fresh)

        print("🌤 APIから取得しキャッシュ: \(city)")
        return fresh
    }
}
