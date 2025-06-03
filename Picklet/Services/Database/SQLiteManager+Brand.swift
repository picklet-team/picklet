import Foundation
import SQLite

extension SQLiteManager {
  func saveBrand(_ brand: Brand) -> Bool {
    do {
      let insert = brandsTable.insert(
        brandId <- brand.id.uuidString,
        brandName <- brand.name,
        brandCreatedAt <- brand.createdAt,
        brandUpdatedAt <- brand.updatedAt)

      try db?.run(insert)
      return true
    } catch {
      print("❌ ブランド保存エラー: \(error)")
      return false
    }
  }

  func loadAllBrands() -> [Brand] {
    var brands: [Brand] = []

    do {
      guard let db = db else { return brands }

      for row in try db.prepare(brandsTable) {
        let brand = Brand(
          id: UUID(uuidString: row[brandId]) ?? UUID(),
          name: row[brandName],
          createdAt: row[brandCreatedAt],
          updatedAt: row[brandUpdatedAt])
        brands.append(brand)
      }
    } catch {
      print("❌ ブランド読み込みエラー: \(error)")
    }

    return brands
  }

  func updateBrand(_ brand: Brand) -> Bool {
    do {
      let update = brandsTable
        .filter(brandId == brand.id.uuidString)
        .update(
          brandName <- brand.name,
          brandUpdatedAt <- Date())

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
}
