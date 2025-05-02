//
//
//

import Foundation
import PostgREST

extension PostgrestResponse {
    func decoded<U: Decodable>(to type: U.Type) throws -> U {
        let decoder = JSONDecoder()
        return try decoder.decode(U.self, from: self.data)
    }
}

extension DateFormatter {
    static let cachedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
