import Foundation
import SQLite

extension SQLiteManager {

  // カテゴリ保存
  func saveCategory(_ category: Category) -> Bool {
    do {
      let insert = categoriesTable.insert(
        categoryId <- category.id.uuidString,
        categoryName <- category.name,
        categoryCreatedAt <- category.createdAt,
        categoryUpdatedAt <- category.updatedAt
        // isDefaultを削除
      )

      try db?.run(insert)
      return true
    } catch {
      print("❌ カテゴリ保存エラー: \(error)")
      return false
    }
  }

  // 全カテゴリ読み込み
  func loadAllCategories() -> [Category] {
    var categories: [Category] = []

    do {
      guard let db = db else { return categories }

      for row in try db.prepare(categoriesTable) {
        let category = Category(
          id: UUID(uuidString: row[categoryId]) ?? UUID(),
          name: row[categoryName],
          createdAt: row[categoryCreatedAt],
          updatedAt: row[categoryUpdatedAt]
          // isDefaultを削除
        )
        categories.append(category)
      }
    } catch {
      print("❌ カテゴリ読み込みエラー: \(error)")
    }

    return categories
  }

  // カテゴリ更新
  func updateCategory(_ category: Category) -> Bool {
    do {
      let update = categoriesTable
        .filter(categoryId == category.id.uuidString)
        .update(
          categoryName <- category.name,
          categoryUpdatedAt <- Date()
          // isDefaultを削除
        )

      guard let db = db else { return false }
      try db.run(update)
      return true
    } catch {
      print("❌ カテゴリ更新エラー: \(error)")
      return false
    }
  }

  // カテゴリ削除
  func deleteCategory(id: UUID) -> Bool {
    do {
      let category = categoriesTable.filter(categoryId == id.uuidString)
      let deleted = try db?.run(category.delete()) ?? 0
      return deleted > 0
    } catch {
      print("❌ カテゴリ削除エラー: \(error)")
      return false
    }
  }
}
