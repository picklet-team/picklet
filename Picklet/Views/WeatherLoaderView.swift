//
//  WeatherLoaderView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct WeatherLoaderView: View {
  @StateObject private var locationManager = LocationManager()
  @State private var weather: Weather?
  @State private var isLoading = true
  @State private var errorMessage: String?

  // オフライン専用のWeatherServiceを使用
  private let weatherService = PickletOfflineWeatherService.shared

  var body: some View {
    Group {
      if isLoading {
        ProgressView("天気情報を取得中...")
      } else if let weather = weather {
        WeatherView(weather: weather)
      } else if let errorMessage = errorMessage {
        Text(errorMessage)
          .foregroundColor(.red)
          .padding()
      }
    }
    .onAppear {
      Task {
        await loadWeather()
      }
    }
    .onChange(of: locationManager.placemark) {
      // プレースマークが更新されたら再読み込み（ただし必要ない場合はスキップ）
      guard weather == nil && errorMessage == nil else { return }
      Task {
        await loadWeather()
      }
    }
  }

  private func loadWeather() async {
    print("🌀 loadWeather called")

    // オフラインモードではシンプルに固定の天気データを使用
    weather = weatherService.getCurrentWeather()
    isLoading = false

    // 位置情報がある場合は、都市名だけログ出力（実際の処理には影響しない）
    if let placemark = locationManager.placemark {
      let prefecture = placemark.administrativeArea ?? "不明"
      let city = placemark.locality ?? placemark.subAdministrativeArea ?? "不明"
      print("🗾 現在地: \(prefecture) / \(city) (オフラインモードのため使用されません)")
    }
  }

  // デモ用に天気をランダムに切り替える関数（実際のアプリでは使用しなくてもOK）
  func refreshRandomWeather() {
    weather = weatherService.generateRandomWeather()
  }
}
