//
//
//

import Foundation

extension DateFormatter {
    static let cachedDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}
