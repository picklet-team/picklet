//
//  WeatherLoaderView.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//


import SwiftUI

struct WeatherLoaderView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var weather: Weather?
    @State private var isLoading = true
    @State private var errorMessage: String?

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
        .onChange(of: locationManager.placemark) {
            guard weather == nil && errorMessage == nil else { return }
            Task {
                await loadWeather()
            }
        }

    }

    private func loadWeather() async {
        print("🌀 loadWeather called")
        guard let placemark = locationManager.placemark else {
            errorMessage = "位置情報が取得できませんでした"
            isLoading = false
            return
        }

        // 県や市の表示確認
        let prefecture = placemark.administrativeArea ?? "不明"
        let city = placemark.locality ?? placemark.subAdministrativeArea ?? "不明"

        print("🗾 現在地: \(prefecture) / \(city)")

        if city == "不明" {
            errorMessage = "位置情報から市区町村を取得できませんでした"
            isLoading = false
            return
        }

        do {
            let fetchedWeather = try await WeatherManager.shared.fetchCachedWeather(for: city)
            self.weather = fetchedWeather
        } catch {
            self.errorMessage = "天気情報の取得に失敗しました: \(error.localizedDescription)"
            print("❌ 天気取得失敗: \(error)")
        }


        isLoading = false
    }

}
