import Foundation

// MARK: - Wear History Management

extension ClothingViewModel {
  /// 着用履歴をローカルストレージから読み込む
  func loadWearHistories() {
    print("📂 SQLiteから着用履歴を読み込み開始")
    wearHistories = SQLiteManager.shared.loadWearHistories()
    print("✅ 着用履歴読み込み完了: \(wearHistories.count)件")
  }

  /// 着用履歴をローカルストレージに保存
  private func saveWearHistories() {
    print("💾 着用履歴を保存開始")

    guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
      print("❌ ドキュメントディレクトリが見つかりません")
      return
    }

    let filePath = documentsPath.appendingPathComponent("wear_histories.json")

    do {
      let data = try JSONEncoder().encode(wearHistories)
      try data.write(to: filePath)
      print("✅ 着用履歴保存完了: \(wearHistories.count)件")
    } catch {
      print("❌ 着用履歴保存エラー: \(error)")
    }
  }

  /// 着用履歴を追加
  func addWearHistory(for clothingId: UUID, notes: String? = nil) {
    print("👕 着用履歴を追加: clothingId=\(clothingId)")

    let history = WearHistory(clothingId: clothingId, notes: notes)
    wearHistories.append(history)

    // 1. SQLiteに着用履歴を保存
    SQLiteManager.shared.saveWearHistories(wearHistories)

    // 2. Clothingの着用回数を更新
    if let index = clothes.firstIndex(where: { $0.id == clothingId }) {
      clothes[index].wearCount += 1
      clothes[index].updatedAt = Date()

      // 3. 更新されたClothingをデータベースに保存
      clothingService.updateClothing(clothes[index])
    }

    print("✅ 着用履歴追加完了")
  }

  /// 特定の服の着用履歴を取得
  func getWearHistories(for clothingId: UUID) -> [WearHistory] {
    return wearHistories.filter { $0.clothingId == clothingId }
  }

  /// 着用回数を取得
  func getWearCount(for clothingId: UUID) -> Int {
    return wearHistories.filter { $0.clothingId == clothingId }.count
  }

  /// 最後の着用日を取得
  func getLastWornDate(for clothingId: UUID) -> Date? {
    return wearHistories
      .filter { $0.clothingId == clothingId }
      .max(by: { $0.wornAt < $1.wornAt })?.wornAt
  }

  /// 1回あたりの着用単価を計算
  func getCostPerWear(for clothingId: UUID) -> Double? {
    guard let clothing = clothes.first(where: { $0.id == clothingId }),
          let price = clothing.purchasePrice
    else { return nil }

    let count = getWearCount(for: clothingId)
    return count.isEmpty ? price : price / Double(count)
  }

  /// 今日着用済みかどうかを判定
  func isWornToday(for clothingId: UUID) -> Bool {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    return wearHistories.contains { history in
      history.clothingId == clothingId &&
        history.wornAt >= today &&
        history.wornAt < tomorrow
    }
  }

  /// 今日の着用履歴を削除
  func removeWearHistoryForToday(for clothingId: UUID) {
    let today = Calendar.current.startOfDay(for: Date())
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

    // 削除対象の履歴数をカウント
    let removedCount = wearHistories.filter { history in
      history.clothingId == clothingId &&
        history.wornAt >= today &&
        history.wornAt < tomorrow
    }.count

    // 着用履歴を削除
    wearHistories.removeAll { history in
      history.clothingId == clothingId &&
        history.wornAt >= today &&
        history.wornAt < tomorrow
    }

    // 1. SQLiteに着用履歴を保存
    SQLiteManager.shared.saveWearHistories(wearHistories)

    // 2. Clothingの着用回数を減らす
    if removedCount > 0, let index = clothes.firstIndex(where: { $0.id == clothingId }) {
      clothes[index].wearCount = max(0, clothes[index].wearCount - removedCount)
      clothes[index].updatedAt = Date()

      // 3. 更新されたClothingをデータベースに保存
      clothingService.updateClothing(clothes[index])
    }
  }
}
