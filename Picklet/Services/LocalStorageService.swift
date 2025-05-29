import Foundation
import UIKit

/// ローカルストレージを管理するサービス（オフライン専用）
class LocalStorageService {
  static let shared = LocalStorageService()

  let fileManager = FileManager.default
  let groupIdentifier = "group.com.yourdomain.picklet" // App Group識別子を設定
  let documentsDirectory: URL
  let userDefaults: UserDefaults

  // 画像保存用のディレクトリ
  let imagesDirectory: URL

  private init() {
    // App Groupのコンテナディレクトリを取得
    if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: groupIdentifier) {
      documentsDirectory = groupURL.appendingPathComponent("Documents")
      userDefaults = UserDefaults(suiteName: groupIdentifier) ?? UserDefaults.standard
    } else {
      // フォールバック: 通常のDocumentsディレクトリ
      documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
      userDefaults = UserDefaults.standard
    }

    // 画像保存用ディレクトリの設定
    imagesDirectory = documentsDirectory.appendingPathComponent("images")

    // 必要なディレクトリを作成
    createDirectoriesIfNeeded()
  }

  // MARK: - Directory Management

  private func createDirectoriesIfNeeded() {
    let directories = [documentsDirectory, imagesDirectory]

    for directory in directories {
      if !fileManager.fileExists(atPath: directory.path) {
        do {
          try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
          print("✅ ディレクトリを作成: \(directory.path)")
        } catch {
          print("❌ ディレクトリ作成エラー: \(error)")
        }
      }
    }
  }

  // MARK: - Debug Methods

  func printStorageInfo() {
    print("📁 LocalStorageService 情報:")
    print("   Documents: \(documentsDirectory.path)")
    print("   Images: \(imagesDirectory.path)")
    print("   UserDefaults Suite: \(groupIdentifier)")
  }

  func clearAllData() {
    // 各拡張ファイルのclearメソッドを呼び出し
    clearAllImages()
    clearAllClothing()
    clearWearHistories()
    print("🗑️ 全てのローカルデータをクリア")
  }
}
