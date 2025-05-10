//
//  OfflineWeatherService.swift
//  Picklet
//
//  Created on 2025/05/10.
//

import CoreLocation
import Foundation

/// オフライン専用の天気情報サービス
/// オフライン環境でも動作するようにハードコードされたデータを提供
class PickletOfflineWeatherService {
  static let shared = PickletOfflineWeatherService()

  private let defaultWeather: Weather
  private let localStorageKey = "offline_weather_data"

  private init() {
    print("🧩 オフラインWeatherServiceを初期化")

    // Get formatted date outside of self reference
    let currentDateString = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter.string(from: Date())
    }()

    // デフォルトの天気データ
    defaultWeather = Weather(
      city: "東京",
      date: currentDateString,
      temperature: 22.0,
      condition: "晴れ",
      icon: "sun.max.fill",
      updatedAt: ISO8601DateFormatter().string(from: Date()))

    // 保存されているデータがあれば読み込む
    loadSavedWeather()
  }

  /// 天気データを取得
  /// - Parameter city: 都市名（オフライン時は無視されます）
  /// - Returns: 天気データ
  func getCurrentWeather(forCity city: String = "東京") -> Weather {
    print("🌤️ オフラインの天気データを提供: \(city)")

    // 保存されているデータまたはデフォルト値を返す
    if let savedData = UserDefaults.standard.data(forKey: localStorageKey),
       let weather = try? JSONDecoder().decode(Weather.self, from: savedData) {
      return weather
    }

    return defaultWeather
  }

  /// 天気データを更新して保存（オフラインでもUIテスト用に天気を変更できるようにする）
  /// - Parameter weather: 保存する天気データ
  func saveWeather(_ weather: Weather) {
    print("💾 オフラインの天気データを保存: \(weather.condition)")

    if let encoded = try? JSONEncoder().encode(weather) {
      UserDefaults.standard.set(encoded, forKey: localStorageKey)
    }
  }

  /// ランダムな天気データを生成（デモやテスト用）
  /// - Returns: ランダムな天気データ
  func generateRandomWeather() -> Weather {
    let conditions = ["晴れ", "くもり", "雨", "雪"]
    let icons = ["sun.max.fill", "cloud.fill", "cloud.rain.fill", "cloud.snow.fill"]

    let randomIndex = Int.random(in: 0 ..< conditions.count)
    let randomTemp = Double.random(in: 10 ... 30)

    let weather = Weather(
      city: "東京",
      date: formattedCurrentDate(),
      temperature: randomTemp,
      condition: conditions[randomIndex],
      icon: icons[randomIndex],
      updatedAt: ISO8601DateFormatter().string(from: Date()))

    // 生成したデータを保存
    saveWeather(weather)

    return weather
  }

  /// 現在日付のフォーマット文字列を取得
  private func formattedCurrentDate() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: Date())
  }

  /// 保存されている天気データを読み込む
  private func loadSavedWeather() {
    if UserDefaults.standard.data(forKey: localStorageKey) == nil {
      // 初回起動時はデフォルト値を保存
      saveWeather(defaultWeather)
    }
  }
}
