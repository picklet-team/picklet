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
  let userID: UUID
  var name: String
  var category: String
  var color: String
  let createdAt: String
  let updatedAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case userID = "user_id"
    case name, category, color
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
