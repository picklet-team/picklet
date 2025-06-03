import Foundation
import SwiftUI

class CategoryManager: ObservableObject {
  @Published var categories: [Category] = []
  private let sqliteManager = SQLiteManager.shared

  init() {
    loadCategories()
  }

  private func loadCategories() {
    categories = sqliteManager.loadAllCategories()
    
    // 初回起動時のみ初期カテゴリを追加
    if categories.isEmpty {
      for initialCategory in Category.initialCategories {
        _ = sqliteManager.saveCategory(initialCategory)
      }
      categories = sqliteManager.loadAllCategories()
    }
  }

  func addCategory(_ name: String) -> Bool {
    let newCategory = Category(name: name)
    if sqliteManager.saveCategory(newCategory) {
      categories.append(newCategory)
      return true
    }
    return false
  }

  func updateCategory(_ category: Category) -> Bool {
    var updatedCategory = category
    updatedCategory.updatedAt = Date()
    
    if sqliteManager.updateCategory(updatedCategory) {
      if let index = categories.firstIndex(where: { $0.id == category.id }) {
        categories[index] = updatedCategory
      }
      return true
    }
    return false
  }

  func deleteCategory(_ category: Category) -> Bool {
    if sqliteManager.deleteCategory(id: category.id) {
      categories.removeAll { $0.id == category.id }
      return true
    }
    return false
  }

  // 複数カテゴリ名を取得
  func getCategoryNames(for ids: [UUID]) -> [String] {
    return ids.compactMap { id in
      categories.first(where: { $0.id == id })?.name
    }
  }

  // 表示用の結合文字列
  func getCategoryDisplayText(for ids: [UUID]) -> String {
    let names = getCategoryNames(for: ids)
    return names.isEmpty ? "未分類" : names.joined(separator: ", ")
  }
}
