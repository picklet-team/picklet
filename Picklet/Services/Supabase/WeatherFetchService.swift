//
//
//

import Foundation
import PostgREST
import Supabase

class WeatherFetchService {
    static let shared = WeatherFetchService()
    
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
}
