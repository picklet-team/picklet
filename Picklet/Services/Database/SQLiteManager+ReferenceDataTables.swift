import Foundation
import SQLite

// MARK: - 3つの別々テーブルでの参照データ管理

extension SQLiteManager {

  // MARK: - Categories Table

  func saveCategory(_ data: ReferenceData) -> Bool {
    do {
      let insert = categoriesTable.insert(
        categoryId <- data.id.uuidString,
        categoryName <- data.name,
        categoryIcon <- data.icon
      )
      try db?.run(insert)
      return true
    } catch {
      print("❌ カテゴリ保存エラー: \(error)")
      return false
    }
  }

  func loadAllCategories() -> [ReferenceData] {
    var categories: [ReferenceData] = []
    do {
      guard let db = db else { return categories }
      for row in try db.prepare(categoriesTable) {
        let category = ReferenceData(
          id: UUID(uuidString: row[categoryId]) ?? UUID(),
          type: .category,
          name: row[categoryName],
          icon: row[categoryIcon]
        )
        categories.append(category)
      }
    } catch {
      print("❌ カテゴリ読み込みエラー: \(error)")
    }
    return categories
  }

  func updateCategory(_ data: ReferenceData) -> Bool {
    do {
      let update = categoriesTable
        .filter(categoryId == data.id.uuidString)
        .update(
          categoryName <- data.name,
          categoryIcon <- data.icon
        )
      guard let db = db else { return false }
      try db.run(update)
      return true
    } catch {
      print("❌ カテゴリ更新エラー: \(error)")
      return false
    }
  }

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

  // MARK: - Brands Table

  func saveBrand(_ data: ReferenceData) -> Bool {
    do {
      let insert = brandsTable.insert(
        brandId <- data.id.uuidString,
        brandName <- data.name,
        brandIcon <- data.icon
      )
      try db?.run(insert)
      return true
    } catch {
      print("❌ ブランド保存エラー: \(error)")
      return false
    }
  }

  func loadAllBrands() -> [ReferenceData] {
    var brands: [ReferenceData] = []
    do {
      guard let db = db else { return brands }
      for row in try db.prepare(brandsTable) {
        let brand = ReferenceData(
          id: UUID(uuidString: row[brandId]) ?? UUID(),
          type: .brand,
          name: row[brandName],
          icon: row[brandIcon]
        )
        brands.append(brand)
      }
    } catch {
      print("❌ ブランド読み込みエラー: \(error)")
    }
    return brands
  }

  func updateBrand(_ data: ReferenceData) -> Bool {
    do {
      let update = brandsTable
        .filter(brandId == data.id.uuidString)
        .update(
          brandName <- data.name,
          brandIcon <- data.icon
        )
      guard let db = db else { return false }
      try db.run(update)
      return true
    } catch {
      print("❌ ブランド更新エラー: \(error)")
      return false
    }
  }

  func deleteBrand(id: UUID) -> Bool {
    do {
      let brand = brandsTable.filter(brandId == id.uuidString)
      let deleted = try db?.run(brand.delete()) ?? 0
      return deleted > 0
    } catch {
      print("❌ ブランド削除エラー: \(error)")
      return false
    }
  }

  // MARK: - Tags Table

  func saveTag(_ data: ReferenceData) -> Bool {
    do {
      let insert = tagsTable.insert(
        tagId <- data.id.uuidString,
        tagName <- data.name,
        tagIcon <- data.icon
      )
      try db?.run(insert)
      return true
    } catch {
      print("❌ タグ保存エラー: \(error)")
      return false
    }
  }

  func loadAllTags() -> [ReferenceData] {
    var tags: [ReferenceData] = []
    do {
      guard let db = db else { return tags }
      for row in try db.prepare(tagsTable) {
        let tag = ReferenceData(
          id: UUID(uuidString: row[tagId]) ?? UUID(),
          type: .tag,
          name: row[tagName],
          icon: row[tagIcon]
        )
        tags.append(tag)
      }
    } catch {
      print("❌ タグ読み込みエラー: \(error)")
    }
    return tags
  }

  func updateTag(_ data: ReferenceData) -> Bool {
    do {
      let update = tagsTable
        .filter(tagId == data.id.uuidString)
        .update(
          tagName <- data.name,
          tagIcon <- data.icon
        )
      guard let db = db else { return false }
      try db.run(update)
      return true
    } catch {
      print("❌ タグ更新エラー: \(error)")
      return false
    }
  }

  func deleteTag(id: UUID) -> Bool {
    do {
      let tag = tagsTable.filter(tagId == id.uuidString)
      let deleted = try db?.run(tag.delete()) ?? 0
      return deleted > 0
    } catch {
      print("❌ タグ削除エラー: \(error)")
      return false
    }
  }

  // MARK: - 統合メソッド（全テーブルから読み込み）

  func loadAllReferenceData() -> [ReferenceData] {
    var allData: [ReferenceData] = []
    allData.append(contentsOf: loadAllCategories())
    allData.append(contentsOf: loadAllBrands())
    allData.append(contentsOf: loadAllTags())
    return allData
  }

  // タイプ別の保存・更新・削除メソッド
  func saveReferenceData(_ data: ReferenceData) -> Bool {
    switch data.type {
    case .category:
      return saveCategory(data)
    case .brand:
      return saveBrand(data)
    case .tag:
      return saveTag(data)
    }
  }

  func updateReferenceData(_ data: ReferenceData) -> Bool {
    switch data.type {
    case .category:
      return updateCategory(data)
    case .brand:
      return updateBrand(data)
    case .tag:
      return updateTag(data)
    }
  }

  func deleteReferenceData(id: UUID, type: ReferenceDataType) -> Bool {
    switch type {
    case .category:
      return deleteCategory(id: id)
    case .brand:
      return deleteBrand(id: id)
    case .tag:
      return deleteTag(id: id)
    }
  }
}
