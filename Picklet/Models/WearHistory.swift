import Foundation

struct WearHistory: Codable, Identifiable, Equatable {
  let id: UUID
  let clothingId: UUID
  let wornAt: Date
  let notes: String?

  init(id: UUID = UUID(), clothingId: UUID, wornAt: Date = Date(), notes: String? = nil) {
    self.id = id
    self.clothingId = clothingId
    self.wornAt = wornAt
    self.notes = notes
  }
}
