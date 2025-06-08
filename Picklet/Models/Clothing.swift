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
    id = UUID()
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

struct Clothing: Identifiable, Codable, Equatable {
  let id: UUID
  var name: String
  var purchasePrice: Double?
  var favoriteRating: Int
  var colors: [ColorData]
  var categoryIds: [UUID]
  var brandId: UUID?
  var tagIds: [UUID]
  var wearCount: Int
  var wearLimit: Int? // 着用上限を追加
  let createdAt: Date
  var updatedAt: Date

  // 新規作成用の初期化メソッド
  init(
    id: UUID = UUID(),
    name: String,
    purchasePrice: Double? = nil,
    favoriteRating: Int = 3,
    colors: [ColorData] = [],
    categoryIds: [UUID] = [],
    brandId: UUID? = nil,
    tagIds: [UUID] = [],
    wearCount: Int = 0,
    wearLimit: Int? = nil // 着用上限
  ) {
    self.id = id
    self.name = name
    self.purchasePrice = purchasePrice
    self.favoriteRating = favoriteRating
    self.colors = colors
    self.categoryIds = categoryIds
    self.brandId = brandId
    self.tagIds = tagIds
    self.wearCount = wearCount
    self.wearLimit = wearLimit
    createdAt = Date() // 現在時刻で作成
    updatedAt = Date()
  }

  // データベースから復元用の初期化メソッド
  init(
    id: UUID,
    name: String,
    purchasePrice: Double? = nil,
    favoriteRating: Int = 3,
    colors: [ColorData] = [],
    categoryIds: [UUID] = [],
    brandId: UUID? = nil,
    tagIds: [UUID] = [],
    wearCount: Int = 0,
    wearLimit: Int? = nil,
    createdAt: Date, // データベースから取得した作成日時
    updatedAt: Date // データベースから取得した更新日時
  ) {
    self.id = id
    self.name = name
    self.purchasePrice = purchasePrice
    self.favoriteRating = favoriteRating
    self.colors = colors
    self.categoryIds = categoryIds
    self.brandId = brandId
    self.tagIds = tagIds
    self.wearCount = wearCount
    self.wearLimit = wearLimit
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
}
