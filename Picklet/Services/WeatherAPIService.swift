//
//
//

import Foundation

class WeatherAPIService {
    static let shared = WeatherAPIService()
    
    private init() {}
    
    func fetchWeatherData(for city: String) async throws -> Weather {
        let apiKey = getOpenWeatherApiKey()
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?q=\(encodedCity)&appid=\(apiKey)&units=metric&lang=ja") else {
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
            id: UUID(),
            city: city,
            date: today,
            temperature: weatherResponse.main.temp,
            condition: weatherResponse.weather.first?.description ?? "不明",
            icon: weatherResponse.weather.first?.icon ?? "01d",
            updated_at: currentTime
        )
    }
}
