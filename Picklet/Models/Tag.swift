import Foundation
import SwiftUI

struct Tag: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  var color: TagColor
  var description: String?
  let createdAt: Date
  var updatedAt: Date

  enum TagColor: String, CaseIterable, Codable {
    case blue
    case green
    case orange
    case red
    case purple
    case pink
    case yellow
    case gray

    var color: Color {
      switch self {
      case .blue: return .blue
      case .green: return .green
      case .orange: return .orange
      case .red: return .red
      case .purple: return .purple
      case .pink: return .pink
      case .yellow: return .yellow
      case .gray: return .gray
      }
    }
  }

  init(id: UUID = UUID(),
       name: String,
       color: TagColor = .blue,
       description: String? = nil,
       createdAt: Date = Date(),
       updatedAt: Date = Date()) {
    self.id = id
    self.name = name
    self.color = color
    self.description = description
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
