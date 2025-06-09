import Foundation

@MainActor
class ReferenceDataManager: ObservableObject {
  @Published var referenceData: [ReferenceData] = []

  private let sqliteManager = SQLiteManager.shared

  init() {
    loadReferenceData()
  }

  // MARK: - Load Data

  private func loadReferenceData() {
    referenceData = sqliteManager.loadAllReferenceData()
  }

  // MARK: - Filter by Type

  func getData(for type: ReferenceDataType) -> [ReferenceData] {
    return referenceData.filter { $0.type == type }
  }

  var categories: [ReferenceData] {
    return getData(for: .category)
  }

  var brands: [ReferenceData] {
    return getData(for: .brand)
  }

  var tags: [ReferenceData] {
    return getData(for: .tag)
  }

  // MARK: - CRUD Operations

  func addData(type: ReferenceDataType, name: String, icon: String = "📁") -> Bool {
    let newData = ReferenceData(
      type: type,
      name: name,
      icon: icon)

    if sqliteManager.saveReferenceData(newData) {
      referenceData.append(newData)
      return true
    }
    return false
  }

  func updateData(_ data: ReferenceData) -> Bool {
    if sqliteManager.updateReferenceData(data) {
      if let index = referenceData.firstIndex(where: { $0.id == data.id }) {
        referenceData[index] = data
      }
      return true
    }
    return false
  }

  func deleteData(_ data: ReferenceData) -> Bool {
    if sqliteManager.deleteReferenceData(id: data.id, type: data.type) {
      referenceData.removeAll { $0.id == data.id }
      return true
    }
    return false
  }

  // MARK: - Helper Methods

  func getDataById(_ id: UUID) -> ReferenceData? {
    return referenceData.first { $0.id == id }
  }

  func getCategoryNames(for ids: [UUID]) -> [String] {
    return ids.compactMap { id in
      categories.first(where: { $0.id == id })?.name
    }
  }

  func getCategoryDisplayText(for ids: [UUID]) -> String {
    let names = getCategoryNames(for: ids)
    return names.isEmpty ? "未分類" : names.joined(separator: ", ")
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
