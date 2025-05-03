//
//  PickletUITests.swift
//  PickletUITests
//
//  Created by al dente on 2025/04/12.
//

import XCTest

final class PickletUITests: XCTestCase {

  override func setUpWithError() throws {
    // Put setup code here. This method is called before the invocation of each test method in the class.

    // In UI tests it is usually best to stop immediately when a failure occurs.
    continueAfterFailure = false

    // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
  }

  override func tearDownWithError() throws {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
  }

  @MainActor
  func testExample() throws {
    // UI tests must launch the application that they test.
    let app = XCUIApplication()
    app.launch()

    // Use XCTAssert and related functions to verify your tests produce the correct results.
  }

  @MainActor
  func testLaunchPerformance() throws {
    if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
      // This measures how long it takes to launch your application.
      measure(metrics: [XCTApplicationLaunchMetric()]) {
        XCUIApplication().launch()
      }
    }
  }
  
  @MainActor
  func testLoginScreen() throws {
    let app = XCUIApplication()
    app.launch()
    
    // ログイン画面の要素を検証
    XCTAssertTrue(app.textFields["emailTextField"].exists, "メールアドレスフィールドが表示されていません")
    XCTAssertTrue(app.secureTextFields["passwordTextField"].exists, "パスワードフィールドが表示されていません")
    XCTAssertTrue(app.buttons["loginButton"].exists, "ログインボタンが表示されていません")
    
    // テキスト入力のテスト
    let emailTextField = app.textFields["emailTextField"]
    emailTextField.tap()
    emailTextField.typeText("test@example.com")
    
    let passwordTextField = app.secureTextFields["passwordTextField"]
    passwordTextField.tap()
    passwordTextField.typeText("password123")
    
    // キーボードを閉じる
    app.buttons["Return"].tap()
    
    // ログインボタンをタップ
    app.buttons["loginButton"].tap()
    
    // ログイン成功後のメイン画面への遷移を確認（5秒のタイムアウト）
    let tabBar = app.tabBars.firstMatch
    let expectation = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: tabBar, handler: nil)
    wait(for: [expectation], timeout: 5.0)
    
    XCTAssertTrue(tabBar.exists, "ログイン後にタブバーが表示されていません")
  }
  
  @MainActor
  func testClothingList() throws {
    let app = XCUIApplication()
    // アプリを既にログイン状態で起動する（テスト用のフラグが必要）
    app.launchArguments = ["UI_TESTING", "LOGGED_IN"]
    app.launch()
    
    // 衣類リスト画面に移動
    app.tabBars.buttons["衣類"].tap()
    
    // 衣類リストが表示されることを確認
    let clothingList = app.collectionViews["clothingListView"]
    XCTAssertTrue(clothingList.exists, "衣類リストが表示されていません")
    
    // 新規追加ボタンを確認
    let addButton = app.buttons["addClothingButton"]
    XCTAssertTrue(addButton.exists, "追加ボタンが表示されていません")
    
    // 衣類アイテムが表示されるまで少し待機
    let clothingCell = clothingList.cells.firstMatch
    let expectation = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: clothingCell, handler: nil)
    wait(for: [expectation], timeout: 3.0)
    
    // 衣類アイテムの詳細画面へ遷移
    if clothingCell.exists {
      clothingCell.tap()
      
      // 詳細画面の要素を確認
      let detailView = app.otherElements["clothingDetailView"]
      XCTAssertTrue(detailView.waitForExistence(timeout: 2.0), "詳細画面が表示されていません")
      
      // 戻るボタンをタップ
      app.navigationBars.buttons.firstMatch.tap()
    }
  }
  
  @MainActor
  func testCaptureFlow() throws {
    let app = XCUIApplication()
    // アプリを既にログイン状態で起動
    app.launchArguments = ["UI_TESTING", "LOGGED_IN"]
    app.launch()
    
    // キャプチャタブに移動
    app.tabBars.buttons["撮影"].tap()
    
    // カメラ/ライブラリ選択画面の要素を確認
    let cameraButton = app.buttons["cameraButton"]
    let libraryButton = app.buttons["libraryButton"]
    
    XCTAssertTrue(cameraButton.exists, "カメラボタンが表示されていません")
    XCTAssertTrue(libraryButton.exists, "ライブラリボタンが表示されていません")
    
    // ライブラリボタンをタップ
    libraryButton.tap()
    
    // ライブラリピッカーが表示されることを確認
    let libraryPicker = app.otherElements["photoLibraryPicker"]
    XCTAssertTrue(libraryPicker.waitForExistence(timeout: 2.0), "ライブラリピッカーが表示されていません")
    
    // 戻るボタンをタップ（テストを続行）
    app.navigationBars.buttons.firstMatch.tap()
  }
  
  @MainActor
  func testWeatherView() throws {
    let app = XCUIApplication()
    // アプリを既にログイン状態で起動
    app.launchArguments = ["UI_TESTING", "LOGGED_IN"]
    app.launch()
    
    // 天気タブに移動
    app.tabBars.buttons["天気"].tap()
    
    // 天気画面の要素を確認
    let weatherView = app.otherElements["weatherView"]
    XCTAssertTrue(weatherView.waitForExistence(timeout: 2.0), "天気画面が表示されていません")
    
    // 天気情報が読み込まれるまで待機
    let temperatureLabel = app.staticTexts["temperatureLabel"]
    XCTAssertTrue(temperatureLabel.waitForExistence(timeout: 5.0), "温度表示が読み込まれませんでした")
    
    // 場所情報を確認
    let locationLabel = app.staticTexts["locationLabel"]
    XCTAssertTrue(locationLabel.exists, "場所情報が表示されていません")
  }
  
  @MainActor
  func testSettingsView() throws {
    let app = XCUIApplication()
    // アプリを既にログイン状態で起動
    app.launchArguments = ["UI_TESTING", "LOGGED_IN"]
    app.launch()
    
    // 設定タブに移動
    app.tabBars.buttons["設定"].tap()
    
    // 設定画面の要素を確認
    let settingsView = app.otherElements["settingsView"]
    XCTAssertTrue(settingsView.waitForExistence(timeout: 2.0), "設定画面が表示されていません")
    
    // ログアウトボタンを確認
    let logoutButton = app.buttons["logoutButton"]
    XCTAssertTrue(logoutButton.exists, "ログアウトボタンが表示されていません")
    
    // バージョン情報を確認
    let versionLabel = app.staticTexts["versionLabel"]
    XCTAssertTrue(versionLabel.exists, "バージョン情報が表示されていません")
  }
}
