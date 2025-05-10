//
//  WeatherView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct WeatherView: View {
  let weather: Weather

  var body: some View {
    VStack(spacing: 8) {
      // SF Symbolsを使用してローカルに天気アイコンを表示
      Image(systemName: getWeatherSymbol(icon: weather.icon))
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
        .foregroundColor(getWeatherColor(condition: weather.condition))
        .accessibility(identifier: "weatherIcon")

      // 場所情報を表示
      Text(weather.city)
        .font(.headline)
        .accessibility(identifier: "locationLabel")

      Text(weather.condition)
        .font(.headline)

      Text("\(weather.temperature, specifier: "%.1f")℃")
        .font(.title)
        .bold()
        .accessibility(identifier: "temperatureLabel")
    }
    .padding()
    .accessibility(identifier: "weatherView")
  }

  /// 天気条件に基づいてSF Symbolsのアイコン名を返す
  private func getWeatherSymbol(icon: String) -> String {
    // すでにSF Symbol名の場合はそのまま使用
    if icon.contains(".") {
      return icon
    }

    // OpenWeather APIのアイコンコードからSF Symbolsへ変換
    switch icon {
    case "01d", "01n": return "sun.max.fill" // 晴れ
    case "02d", "02n": return "cloud.sun.fill" // 薄曇り
    case "03d", "03n": return "cloud.fill" // 曇り
    case "04d", "04n": return "smoke.fill" // 厚い曇り
    case "09d", "09n": return "cloud.drizzle.fill" // 小雨
    case "10d", "10n": return "cloud.rain.fill" // 雨
    case "11d", "11n": return "cloud.bolt.fill" // 雷雨
    case "13d", "13n": return "cloud.snow.fill" // 雪
    case "50d", "50n": return "cloud.fog.fill" // 霧
    default: return "sun.max.fill" // デフォルト
    }
  }

  /// 天気条件に基づいて色を返す
  private func getWeatherColor(condition: String) -> Color {
    switch condition.lowercased() {
    case let c where c.contains("晴れ") || c.contains("sun") || c.contains("clear"):
      return .yellow
    case let c where c.contains("曇") || c.contains("cloud"):
      return .gray
    case let c where c.contains("雨") || c.contains("rain") || c.contains("drizzle"):
      return .blue
    case let c where c.contains("雪") || c.contains("snow"):
      return .cyan
    case let c where c.contains("霧") || c.contains("fog") || c.contains("mist"):
      return .gray.opacity(0.7)
    case let c where c.contains("雷") || c.contains("thunder") || c.contains("storm"):
      return .purple
    default:
      return .blue
    }
  }
}
