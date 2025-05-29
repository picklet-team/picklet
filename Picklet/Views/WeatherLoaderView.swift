//
//  WeatherLoaderView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct WeatherLoaderView: View {
  @StateObject private var locationManager = LocationManager()
  @EnvironmentObject private var themeManager: ThemeManager
  @State private var weather: Weather?
  @State private var isLoading = true
  @State private var errorMessage: String?
  @State private var lastLoadedCity: String?

  // 実際の天気APIサービスを使用
  private let weatherAPIService = WeatherAPIService.shared

  var body: some View {
    NavigationView {
      ZStack {
        // 背景グラデーション
        themeManager.currentTheme.backgroundGradient
          .ignoresSafeArea()

        Group {
          if isLoading {
            ProgressView("天気情報を取得中...")
              .tint(themeManager.currentTheme.primaryColor)
          } else if let weather = weather {
            WeatherView(weather: weather)
          } else if let errorMessage = errorMessage {
            VStack(spacing: 16) {
              Text(errorMessage)
                .foregroundColor(.red)
                .padding()

              Button("再試行") {
                Task {
                  await loadWeather(force: true)
                }
              }
              .buttonStyle(.bordered)
              .tint(themeManager.currentTheme.primaryColor)
            }
          }
        }
      }
      .navigationTitle("天気")
      .onAppear {
        Task {
          await loadWeather()
        }
      }
      .onChange(of: locationManager.placemark) { _, newPlacemark in
        if newPlacemark != nil {
          Task {
            await loadWeather()
          }
        }
      }
    }
  }

  private func loadWeather(force: Bool = false) async {
    // 位置情報から都市名を取得
    let city = locationManager.placemark?.locality ??
      locationManager.placemark?.subAdministrativeArea ?? "東京"

    // 同じ都市で強制更新でない場合はスキップ
    if !force && lastLoadedCity == city && weather != nil {
      print("🔄 同じ都市(\(city))のため天気取得をスキップ")
      return
    }

    isLoading = true
    errorMessage = nil

    do {
      print("🗾 天気取得開始: \(city)")
      weather = try await weatherAPIService.fetchWeatherData(for: city)
      lastLoadedCity = city
      print("🌤️ 天気データ取得成功: \(weather?.condition ?? "不明")")
    } catch {
      errorMessage = "天気データの取得に失敗しました: \(error.localizedDescription)"
      print("❌ 天気データ取得エラー: \(error)")
    }

    isLoading = false
  }
}
