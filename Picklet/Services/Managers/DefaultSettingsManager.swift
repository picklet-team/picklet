import Foundation

class DefaultSettingsManager: ObservableObject {
  @Published var defaultWearLimit: Int? = 30

  private let userDefaults = UserDefaults.standard
  private let defaultWearLimitKey = "defaultWearLimit"

  init() {
    loadSettings()
  }

  func loadSettings() {
    if userDefaults.object(forKey: defaultWearLimitKey) == nil {
      // 初回起動時は30を設定
      defaultWearLimit = 30
      userDefaults.set(30, forKey: defaultWearLimitKey)
    } else {
      let savedValue = userDefaults.integer(forKey: defaultWearLimitKey)
      defaultWearLimit = savedValue == 0 ? nil : savedValue
    }
  }

  func saveDefaultWearLimit(_ limit: Int?) {
    if let limit = limit {
      userDefaults.set(limit, forKey: defaultWearLimitKey)
    } else {
      userDefaults.removeObject(forKey: defaultWearLimitKey)
    }
    defaultWearLimit = limit
  }
}
