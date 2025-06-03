import Foundation
import SwiftUI

class BrandManager: ObservableObject {
  @Published var brands: [Brand] = []
  private let sqliteManager = SQLiteManager.shared

  init() {
    loadBrands()
  }

  private func loadBrands() {
    brands = sqliteManager.loadAllBrands()

    // 初回起動時のみ初期ブランドを追加
    if brands.isEmpty {
      for initialBrand in Brand.initialBrands {
        _ = sqliteManager.saveBrand(initialBrand)
      }
      brands = sqliteManager.loadAllBrands()
    }
  }

  func addBrand(_ name: String) -> Bool {
    let newBrand = Brand(name: name)
    if sqliteManager.saveBrand(newBrand) {
      brands.append(newBrand)
      return true
    }
    return false
  }

  func updateBrand(_ brand: Brand) -> Bool {
    var updatedBrand = brand
    updatedBrand.updatedAt = Date()

    if sqliteManager.updateBrand(updatedBrand) {
      if let index = brands.firstIndex(where: { $0.id == brand.id }) {
        brands[index] = updatedBrand
      }
      return true
    }
    return false
  }

  func deleteBrand(_ brand: Brand) -> Bool {
    if sqliteManager.deleteBrand(id: brand.id) {
      brands.removeAll { $0.id == brand.id }
      return true
    }
    return false
  }

  func getBrandName(for id: UUID?) -> String {
    guard let id = id,
          let brand = brands.first(where: { $0.id == id })
    else {
      return "未選択"
    }
    return brand.name
  }
}
