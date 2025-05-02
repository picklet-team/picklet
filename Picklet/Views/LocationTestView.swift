//
//  LocationTestView.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct LocationTestView: View {
  @StateObject private var locationManager = LocationManager()

  var body: some View {
    VStack {
      if let placemark = locationManager.placemark {
        Text("都道府県: \(placemark.administrativeArea ?? "不明")")
        Text("市区町村: \(placemark.locality ?? "不明")")
      } else if let error = locationManager.locationError {
        Text("エラー: \(error.localizedDescription)")
      } else {
        Text("位置情報を取得中...")
      }
    }
    .padding()
  }
}
