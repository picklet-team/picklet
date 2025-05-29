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
  var purchaseDate: Date? // 追加
  var purchasePrice: Double? // 追加
  let createdAt: Date
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case name, category, color
    case purchaseDate = "purchase_date" // 追加
    case purchasePrice = "purchase_price" // 追加
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  init(id: UUID = UUID(),
       name: String = "",
       category: String = "",
       color: String = "",
       purchaseDate: Date? = nil, // 追加
       purchasePrice: Double? = nil, // 追加
       createdAt: Date = Date(),
       updatedAt: Date = Date()) {
    self.id = id
    self.name = name
    self.category = category
    self.color = color
    self.purchaseDate = purchaseDate // 追加
    self.purchasePrice = purchasePrice // 追加
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
