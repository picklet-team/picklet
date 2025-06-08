import Foundation

struct Category: Codable, Identifiable, Equatable {
  let id: UUID
  var name: String
  let createdAt: Date
  var updatedAt: Date

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  init(id: UUID = UUID(),
       name: String,
       createdAt: Date = Date(),
       updatedAt: Date = Date()) {
    self.id = id
    self.name = name
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  // 初期カテゴリ（アプリインストール時のみ作成）
  static let initialCategories: [Category] = [
    Category(name: "Tシャツ"),
    Category(name: "シャツ"),
    Category(name: "パンツ"),
    Category(name: "スカート")
  ]
}
