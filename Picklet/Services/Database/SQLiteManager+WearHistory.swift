import Foundation
import SQLite

// MARK: - Wear History Management
extension SQLiteManager {

  /// 着用履歴を保存
  func saveWearHistories(_ histories: [WearHistory]) {
    do {
      // 既存データを削除
      try db?.run(wearHistoriesTable.delete())

      // 新しいデータを挿入
      for history in histories {
        let insert = wearHistoriesTable.insert([
          wearId <- history.id.uuidString,
          wearClothingId <- history.clothingId.uuidString,
          wearWornAt <- history.wornAt
        ])

        try db?.run(insert)
      }

      print("✅ SQLite: 着用履歴保存完了 - \(histories.count)件")
    } catch {
      print("❌ SQLite: 着用履歴保存エラー - \(error)")
    }
  }

  /// 着用履歴を読み込み
  func loadWearHistories() -> [WearHistory] {
    do {
      var histories: [WearHistory] = []

      // db変数が存在することを確認
      guard let db = db else { return [] }

      for row in try db.prepare(wearHistoriesTable) {
        let history = WearHistory(
          id: UUID(uuidString: row[wearId])!,
          clothingId: UUID(uuidString: row[wearClothingId])!,
          wornAt: row[wearWornAt]
        )
        histories.append(history)
      }

      print("✅ SQLite: 着用履歴読み込み完了 - \(histories.count)件")
      return histories
    } catch {
      print("❌ SQLite: 着用履歴読み込みエラー - \(error)")
      return []
    }
  }

  /// 今日の着用履歴を削除
  func deleteWearHistoryForToday(clothingId: UUID) {
    do {
      let today = Calendar.current.startOfDay(for: Date())
      let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

      let query = wearHistoriesTable.filter(
        wearClothingId == clothingId.uuidString &&
        wearWornAt >= today &&
        wearWornAt < tomorrow
      )

      let deleted = try db?.run(query.delete()) ?? 0
      print("✅ SQLite: 今日の着用履歴削除 - \(clothingId) (\(deleted)件)")
    } catch {
      print("❌ SQLite: 今日の着用履歴削除エラー - \(error)")
    }
  }

  /// 全ての着用履歴を削除
  func clearWearHistories() {
    do {
      try db?.run(wearHistoriesTable.delete())
      print("✅ SQLite: 全着用履歴削除完了")
    } catch {
      print("❌ SQLite: 全着用履歴削除エラー - \(error)")
    }
  }
}
