import Foundation

struct Brand: Codable, Identifiable, Equatable {
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

  // 初期ブランド（アプリインストール時のみ作成）
  static let initialBrands: [Brand] = [
    Brand(name: "Uniqlo"),
    Brand(name: "Nike"),
    Brand(name: "Adidas"),
    Brand(name: "H&M"),
    Brand(name: "Zara")
  ]
}
