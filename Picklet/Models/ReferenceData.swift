import Foundation
import SwiftUI

enum ReferenceDataType: String, CaseIterable, Codable {
  case category
  case brand
  case tag

  var displayName: String {
    switch self {
    case .category: return "カテゴリ"
    case .brand: return "ブランド"
    case .tag: return "タグ"
    }
  }

  var defaultIcon: String {
    switch self {
    case .category: return "🏷️"
    case .brand: return "⭐"
    case .tag: return "#️⃣"
    }
  }

  var themeColor: Color {
    switch self {
    case .category: return .blue
    case .brand: return .purple
    case .tag: return .green
    }
  }
}

struct ReferenceData: Identifiable, Codable, Equatable {
  let id: UUID
  let type: ReferenceDataType
  var name: String
  var icon: String

  init(id: UUID = UUID(),
       type: ReferenceDataType,
       name: String,
       icon: String? = nil) {
    self.id = id
    self.type = type
    self.name = name
    self.icon = icon ?? type.defaultIcon
  }
}
