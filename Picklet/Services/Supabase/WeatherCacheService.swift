//
//
//

import Foundation
import PostgREST
import Supabase

class WeatherCacheService {
    static let shared = WeatherCacheService()
    
    private let client: SupabaseClient
    
    private init() {
        self.client = AuthService.shared.client
    }
    
    
    func fetchWeatherCache(for city: String) async throws -> Weather {
        let today = DateFormatter.cachedDateFormatter.string(from: Date())
        
        let response =
            try await client
            .from("weather_cache")
            .select("*")
            .eq("city", value: city)
            .eq("date", value: today)
            .limit(1)
            .execute()
        
        return try response.decoded(to: Weather.self)
    }
    
    func insertWeatherCache(_ weather: Weather) async throws {
        _ =
            try await client
            .from("weather_cache")
            .insert(weather)
            .execute()
    }
}
