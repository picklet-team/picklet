//
//
//

import Foundation

// OpenWeatherMap APIのレスポンス構造体を定義
struct OpenWeatherResponse: Codable {
    let main: Main
    let weather: [WeatherInfo]
    let name: String

    struct Main: Codable {
        let temp: Double
        let humidity: Int
    }

    struct WeatherInfo: Codable {
        let main: String
        let description: String
        let icon: String
    }
}

class WeatherAPIService {
  static let shared = WeatherAPIService()

  private init() {}

  // .env.localファイルまたはConfig.plistからAPIキーを取得
  private func getOpenWeatherApiKey() -> String {
    // 1. まずBundleリソースから.env.localを探す
    if let envPath = Bundle.main.path(forResource: ".env", ofType: "local") {
        do {
            let content = try String(contentsOfFile: envPath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix("#") || trimmedLine.isEmpty {
                    continue
                }

                let parts = trimmedLine.components(separatedBy: "=")
                if parts.count == 2 && parts[0].trimmingCharacters(in: .whitespaces) == "OPENWEATHER_API_KEY" {
                    let apiKey = parts[1].trimmingCharacters(in: .whitespaces)
                    print("🔑 .env.localからAPIキーを取得しました")
                    return apiKey
                }
            }
        } catch {
            print("❌ Bundle .env.localファイルの読み込みエラー: \(error)")
        }
    }

    // 2. Config.plistから取得を試す
    if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["OPENWEATHER_API_KEY"] as? String {
        print("🔑 Config.plistからAPIキーを取得しました")
        return apiKey
    }

    // 3. デバッグ用のフォールバック
    #if DEBUG
    print("⚠️ デバッグモード: ハードコードされたAPIキーを使用")
    return "fdfe0ddc982ebfd841e6c25ac7fee5c1"
    #else
    fatalError("OPENWEATHER_API_KEY not found. Please add .env.local to app bundle or create Config.plist")
    #endif
  }

  func fetchWeatherData(for city: String) async throws -> Weather {
    let apiKey = getOpenWeatherApiKey()

    let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city

    let urlString = "https://api.openweathermap.org/data/2.5/weather" +
      "?q=\(encodedCity)" +
      "&appid=\(apiKey)" +
      "&units=metric" +
      "&lang=ja"

    guard let url = URL(string: urlString) else {
      throw NSError(
        domain: "weather", code: 400, userInfo: [NSLocalizedDescriptionKey: "無効な都市名です"])
    }

    let (data, response) = try await URLSession.shared.data(from: url)

    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
      throw NSError(
        domain: "weather", code: (response as? HTTPURLResponse)?.statusCode ?? 500,
        userInfo: [NSLocalizedDescriptionKey: "天気データの取得に失敗しました"])
    }

    let decoder = JSONDecoder()
    let weatherResponse = try decoder.decode(OpenWeatherResponse.self, from: data)

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let today = dateFormatter.string(from: Date())

    let iso8601DateFormatter = ISO8601DateFormatter()
    let currentTime = iso8601DateFormatter.string(from: Date())

    return Weather(
      city: city,
      date: today,
      temperature: weatherResponse.main.temp,
      condition: weatherResponse.weather.first?.description ?? "不明",
      icon: weatherResponse.weather.first?.icon ?? "01d",
      updatedAt: currentTime)
  }
}
