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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
