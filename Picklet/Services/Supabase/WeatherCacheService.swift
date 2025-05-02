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
    
    func insertWeatherCache(_ weather: Weather) async throws {
        _ =
            try await client
            .from("weather_cache")
            .insert(weather)
            .execute()
    }
}
