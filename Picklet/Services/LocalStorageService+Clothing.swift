import Foundation

// MARK: - Clothing Data Management
extension LocalStorageService {

  /// 衣類データを保存
  /// - Parameter clothing: 保存する衣類データ
  /// - Returns: 保存成功の可否
  func saveClothing(_ clothing: Clothing) -> Bool {
    let clothingDirectory = documentsDirectory.appendingPathComponent("clothing")

    // clothingディレクトリが存在しない場合は作成
    if !fileManager.fileExists(atPath: clothingDirectory.path) {
      do {
        try fileManager.createDirectory(at: clothingDirectory, withIntermediateDirectories: true, attributes: nil)
      } catch {
        print("❌ clothingディレクトリ作成エラー: \(error)")
        return false
      }
    }

    let fileURL = clothingDirectory.appendingPathComponent("\(clothing.id.uuidString).json")
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601

    do {
      let data = try encoder.encode(clothing)
      try data.write(to: fileURL)

      // IDリストも更新
      updateClothingIdList(add: clothing.id)

      print("✅ 衣類データ保存成功: \(clothing.name)")
      return true
    } catch {
      print("❌ 衣類データ保存エラー: \(error)")
      return false
    }
  }

  /// 衣類データを読み込み
  /// - Parameter id: 衣類ID
  /// - Returns: 読み込んだ衣類データ
  func loadClothing(id: UUID) -> Clothing? {
    let clothingDirectory = documentsDirectory.appendingPathComponent("clothing")
    let fileURL = clothingDirectory.appendingPathComponent("\(id.uuidString).json")

    guard fileManager.fileExists(atPath: fileURL.path) else {
      print("⚠️ 衣類ファイルが存在しません: \(id)")
      return nil
    }

    do {
      let data = try Data(contentsOf: fileURL)
      let decoder = JSONDecoder()
      decoder.dateDecodingStrategy = .iso8601
      let clothing = try decoder.decode(Clothing.self, from: data)
      return clothing
    } catch {
      print("❌ 衣類データ読み込みエラー: \(error)")
      return nil
    }
  }

  /// 全ての衣類データを読み込み
  /// - Returns: 衣類データの配列
  func loadAllClothing() -> [Clothing] {
    let clothingIds = getClothingIdList()
    var clothes: [Clothing] = []

    for id in clothingIds {
      if let clothing = loadClothing(id: id) {
        clothes.append(clothing)
      }
    }

    print("✅ 衣類データ読み込み: \(clothes.count)件")
    return clothes
  }

  /// 衣類データを削除
  /// - Parameter id: 衣類ID
  /// - Returns: 削除成功の可否
  func deleteClothing(id: UUID) -> Bool {
    let clothingDirectory = documentsDirectory.appendingPathComponent("clothing")
    let fileURL = clothingDirectory.appendingPathComponent("\(id.uuidString).json")

    // ファイル削除
    if fileManager.fileExists(atPath: fileURL.path) {
      do {
        try fileManager.removeItem(at: fileURL)
        print("✅ 衣類ファイル削除成功: \(id)")
      } catch {
        print("❌ 衣類ファイル削除エラー: \(error)")
        return false
      }
    }

    // IDリストからも削除
    updateClothingIdList(remove: id)

    // 関連する画像メタデータも削除
    deleteImageMetadata(for: id)

    return true
  }

  /// 衣類IDリストを取得
  /// - Returns: 衣類IDの配列
  func getClothingIdList() -> [UUID] {
    guard let data = userDefaults.data(forKey: "clothing_id_list") else {
      return []
    }

    do {
      let idStrings = try JSONDecoder().decode([String].self, from: data)
      return idStrings.compactMap { UUID(uuidString: $0) }
    } catch {
      print("❌ 衣類IDリスト読み込みエラー: \(error)")
      return []
    }
  }

  /// 衣類IDリストを更新
  /// - Parameters:
  ///   - add: 追加するID
  ///   - remove: 削除するID
  private func updateClothingIdList(add: UUID? = nil, remove: UUID? = nil) {
    var ids = getClothingIdList()

    if let addId = add, !ids.contains(addId) {
      ids.append(addId)
    }

    if let removeId = remove {
      ids.removeAll { $0 == removeId }
    }

    let idStrings = ids.map { $0.uuidString }

    do {
      let data = try JSONEncoder().encode(idStrings)
      userDefaults.set(data, forKey: "clothing_id_list")
      userDefaults.synchronize()
    } catch {
      print("❌ 衣類IDリスト保存エラー: \(error)")
    }
  }

  /// 全ての衣類データをクリア
  func clearAllClothing() {
    // clothingディレクトリの中身を削除
    let clothingDirectory = documentsDirectory.appendingPathComponent("clothing")
    if fileManager.fileExists(atPath: clothingDirectory.path) {
      do {
        try fileManager.removeItem(at: clothingDirectory)
        print("✅ 全ての衣類ファイルを削除")
      } catch {
        print("❌ 衣類ファイル削除エラー: \(error)")
      }
    }

    // IDリストもクリア
    userDefaults.removeObject(forKey: "clothing_id_list")
    userDefaults.synchronize()
    print("✅ 衣類IDリストをクリア")
  }
}
