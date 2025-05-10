//
//  Clothing.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

// Models/Clothing.swift
import Foundation

struct Clothing: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  var category: String
  var color: String
  let createdAt: Date
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case name, category, color
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  init(id: UUID = UUID(),
       name: String = "",
       category: String = "",
       color: String = "",
       createdAt: Date = Date(),
       updatedAt: Date = Date()) {
    self.id = id
    self.name = name
    self.category = category
    self.color = color
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
