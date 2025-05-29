import Foundation

// MARK: - 着用履歴管理

extension LocalStorageService {
  /// 着用履歴を保存
  /// - Parameter histories: 着用履歴の配列
  func saveWearHistories(_ histories: [WearHistory]) {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    do {
      let data = try encoder.encode(histories)
      userDefaults.set(data, forKey: "wear_histories")
      userDefaults.synchronize()
      print("✅ 着用履歴を保存: \(histories.count)件")
    } catch {
      print("❌ 着用履歴保存エラー: \(error)")
    }
  }

  /// 着用履歴を読み込み
  /// - Returns: 着用履歴の配列
  func loadWearHistories() -> [WearHistory] {
    guard let data = userDefaults.data(forKey: "wear_histories") else {
      print("⚠️ 着用履歴がローカルに存在しません")
      return []
    }

    do {
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let histories = try decoder.decode([WearHistory].self, from: data)
      print("✅ 着用履歴を読み込み: \(histories.count)件")
      return histories
    } catch {
      print("❌ 着用履歴読み込みエラー: \(error)")
      return []
    }
  }

  /// 着用履歴をクリア
  func clearWearHistories() {
    userDefaults.removeObject(forKey: "wear_histories")
    userDefaults.synchronize()
    print("✅ 着用履歴をクリア")
  }
}
