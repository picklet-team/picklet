//
//  Clothing.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

// Models/Clothing.swift
import Foundation
import SwiftUI

struct ColorData: Codable, Identifiable, Hashable, Equatable {
  let id: UUID
  let hue: Double
  let saturation: Double
  let brightness: Double

  init(hue: Double, saturation: Double, brightness: Double) {
    self.id = UUID()
    self.hue = hue
    self.saturation = saturation
    self.brightness = brightness
  }

  var color: Color {
    return Color(hue: hue, saturation: saturation, brightness: brightness)
  }

  static func == (lhs: ColorData, rhs: ColorData) -> Bool {
    return abs(lhs.hue - rhs.hue) < 0.01 &&
           abs(lhs.saturation - rhs.saturation) < 0.01 &&
           abs(lhs.brightness - rhs.brightness) < 0.01
  }
}

struct Clothing: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  var purchasePrice: Double?
  var favoriteRating: Int
  var colors: [ColorData]
  var categoryIds: [UUID]
  var brandId: UUID? // ブランドID追加
  var tagIds: [UUID] // タグIDの配列追加
  let createdAt: Date
  let updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case purchasePrice = "purchase_price"
    case favoriteRating = "favorite_rating"
    case colors
    case categoryIds = "category_ids"
    case brandId = "brand_id"
    case tagIds = "tag_ids"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  init(id: UUID = UUID(),
       name: String = "",
       purchasePrice: Double? = nil,
       favoriteRating: Int = 3,
       colors: [ColorData] = [],
       categoryIds: [UUID] = [],
       brandId: UUID? = nil,
       tagIds: [UUID] = [],
       createdAt: Date = Date(),
       updatedAt: Date = Date()) {
    self.id = id
    self.name = name
    self.purchasePrice = purchasePrice
    self.favoriteRating = favoriteRating
    self.colors = Array(colors.prefix(3))
    self.categoryIds = categoryIds
    self.brandId = brandId
    self.tagIds = tagIds
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
