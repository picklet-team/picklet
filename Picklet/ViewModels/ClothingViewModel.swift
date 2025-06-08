import Foundation
import SwiftUI

@MainActor
class ClothingViewModel: ObservableObject {
  @Published var clothes: [Clothing] = []
  @Published var wearHistories: [WearHistory] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var imageSetsMap: [UUID: [EditableImageSet]] = [:]

  // LocalStorageServiceの代わりにSQLiteManagerを使用
  let dataManager = SQLiteManager.shared
  let imageLoaderService = ImageLoaderService.shared
  let clothingService = ClothingService.shared

  // デバッグ用
  @Published var imageLoadStatus: [String: String] = [:]

  init(skipInitialLoad: Bool = false) {
    print("🧠 ClothingViewModel 初期化, skipInitialLoad: \(skipInitialLoad)")
    if !skipInitialLoad {
      loadClothings()
      loadWearHistories()
    }
  }

  // デバッグ情報を出力する関数
  func printDebugInfo() {
    print("🔍 ClothingViewModel デバッグ情報:")
    print("🧵 clothes 数: \(clothes.count)")
    print("🖼️ imageSetsMap エントリー数: \(imageSetsMap.count)")

    // 各服の情報をデバッグ
    for clothing in clothes {
      let imageSets = imageSetsMap[clothing.id] ?? []
      print("  - \(clothing.name): \(imageSets.count) 画像セット")
    }
  }

  /// ローカルストレージから全ての衣類を読み込む
  func loadClothings() {
    print("📂 ローカルストレージから衣類を読み込み開始")

    isLoading = true
    // ClothingServiceを使って全ての衣類を読み込む
    clothes = clothingService.fetchClothes()

    // 画像も読み込む
    Task {
      await loadAllImages()
      isLoading = false
    }

    print("✅ 衣類読み込み完了: \(clothes.count)件")
  }

  // MARK: - 着用履歴機能

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
    // swiftlint:disable:next empty_count
    return count == 0 ? price : price / Double(count)
  }

  /// メインエントリーポイント - 服の保存（新規 or 更新）
  func saveClothing(_ clothing: Clothing, imageSets: [EditableImageSet], isNew: Bool) {
    print("📝 saveClothing 開始: ID=\(clothing.id), isNew=\(isNew)")

    isLoading = true

    // ステップ1: 衣類データを保存
    let success = if isNew {
      clothingService.addClothing(clothing)
    } else {
      clothingService.updateClothing(clothing)
    }

    if !success {
      errorMessage = "衣類データの保存に失敗しました"
      isLoading = false
      return
    }

    // ステップ2: ローカルストレージに画像を保存
    let localSavedSets = saveImagesToLocalStorage(clothing.id, imageSets: imageSets)

    // ステップ3: UIを更新
    updateLocalImagesCache(clothing.id, imageSets: localSavedSets)

    // ステップ4: UIの衣類リストを更新
    // 修正: 新規か更新かに関わらず、配列に存在すれば更新、なければ追加するロジックに統一
    if let index = clothes.firstIndex(where: { $0.id == clothing.id }) {
      clothes[index] = clothing // 既存の場合、更新
    } else {
      clothes.append(clothing) // 新規の場合、追加
    }

    isLoading = false
    printDebugInfo()
  }

  /// 画像をローカルストレージに保存
  private func saveImagesToLocalStorage(_ clothingId: UUID, imageSets: [EditableImageSet]) -> [EditableImageSet] {
    print("💾 ローカルストレージへ画像を保存: clothingId=\(clothingId)")
    var updatedSets: [EditableImageSet] = []

    for var set in imageSets {
      // オリジナル画像を保存
      if set.original != UIImage(systemName: "photo") {
        if imageLoaderService.saveImage(set.original, for: clothingId, imageId: set.id) {
          print("✅ オリジナル画像をローカルに保存: \(set.id)")
          set.isNew = false
        }
      }

      // マスク画像があれば保存
      if let mask = set.mask {
        let maskFilename = "\(set.id.uuidString)_mask.jpg" // ファイル名を生成
        if dataManager.saveImage(mask, filename: maskFilename) { // 修正: filename:を使用
          print("✅ マスク画像をローカルに保存: \(maskFilename)")

          // メタデータを更新
          var metadata = dataManager.loadImageMetadata(for: clothingId)
          if let index = metadata.firstIndex(where: { $0.id == set.id }) {
            metadata[index] = metadata[index].updatingLocalPath(maskLocalPath: maskFilename)
            dataManager.saveImageMetadata(metadata, for: clothingId) // 修正: 引数順序を変更
          }
        }
      }

      // AIマスク画像があれば保存
      if let aimask = set.aimask {
        let aimaskFilename = "\(set.id.uuidString)_aimask.jpg" // ファイル名を生成
        if dataManager.saveImage(aimask, filename: aimaskFilename) { // 修正: filename:を使用
          print("✅ AIマスク画像をローカルに保存: \(aimaskFilename)")
        }
      }

      updatedSets.append(set)
    }

    return updatedSets
  }

  /// UIの即時更新のためにメモリ内の画像キャッシュを更新
  public func updateLocalImagesCache(_ clothingId: UUID, imageSets: [EditableImageSet]) {
    // 編集中の画像をすぐに表示できるようにキャッシュ
    imageSetsMap[clothingId] = imageSets
    print("✅ 即時表示用に画像キャッシュ更新: \(clothingId)")
  }

  /// 全ての服に関連する画像を読み込む
  func loadAllImages() async {
    print("🖼️ loadAllImages 開始")
    var newMap: [UUID: [EditableImageSet]] = [:]

    // プレースホルダー画像を作成
    let placeholderImage = UIImage(systemName: "photo") ?? UIImage()

    for clothing in clothes {
      // ローカルストレージからメタデータを取得
      let images = dataManager.loadImageMetadata(for: clothing.id)
      print("📷 \(clothing.id)の画像メタデータを取得: \(images.count)件")

      // 画像セットを作成
      var imageSets: [EditableImageSet] = []

      for image in images {
        var original: UIImage = placeholderImage
        let aimask: UIImage? = nil
        var mask: UIImage?

        // オリジナル画像を読み込む
        if let originalPath = image.originalLocalPath {
          if let loadedImage = dataManager.loadImage(filename: originalPath) { // 修正: from: → filename:
            original = loadedImage
            print("✅ ローカルからオリジナル画像を読み込み: \(originalPath)")
          }
        }

        // マスク画像を読み込む
        if let maskPath = image.maskLocalPath {
          if let loadedMask = dataManager.loadImage(filename: maskPath) { // 修正: from: → filename:
            mask = loadedMask
            print("✅ ローカルからマスク画像を読み込み: \(maskPath)")
          }
        }

        // EditableImageSetを構築
        let set = EditableImageSet(
          id: image.id,
          original: original,
          aimask: aimask,
          mask: mask,
          isNew: false)

        imageSets.append(set)
      }

      newMap[clothing.id] = imageSets
    }

    imageSetsMap = newMap
    print("✅ 全画像読み込み完了: \(newMap.count)アイテム")
  }

  /// 服IDから画像を読み込むメソッド（ビュー層からの呼び出し用）
  func getImageForClothing(_ clothingId: UUID) -> UIImage? {
    // キャッシュから画像を取得
    if let imageSets = imageSetsMap[clothingId], let firstSet = imageSets.first {
      // すでにキャッシュされた画像がある場合はそれを返す
      if firstSet.original != UIImage(systemName: "photo") {
        return firstSet.original
      }
    }

    // キャッシュにない場合はローカルストレージから検索
    return imageLoaderService.loadFirstImageForClothing(clothingId)
  }

  /// 服を削除
  func deleteClothing(_ clothing: Clothing) {
    print("🗑️ deleteClothing 開始: ID=\(clothing.id)")

    // ClothingServiceを使って削除
    if clothingService.deleteClothing(clothing) {
      // UIから削除
      if let idx = clothes.firstIndex(where: { $0.id == clothing.id }) {
        clothes.remove(at: idx)
        print("✅ ローカル配列からアイテムを削除")
      }
      // 画像キャッシュからも削除
      imageSetsMap.removeValue(forKey: clothing.id)
      print("✅ imageSetsMapからエントリーを削除")
    } else {
      errorMessage = "衣類の削除に失敗しました"
    }
  }

  /// サーバーとローカルデータを同期する
  func syncIfNeeded() async {
    print("🔄 データ同期チェック")

    // 既にロード中の場合は何もしない
    if isLoading {
      return
    }

    isLoading = true

    // オンラインか確認し、必要に応じてサーバーからデータを取得
    // このサンプルでは簡単にローカルデータの再読み込みのみ実行
    loadClothings()

    // 画像も再読み込み
    await loadAllImages()

    print("✅ 同期完了")

    isLoading = false
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
