//
//  WeatherView.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import SwiftUI

struct WeatherView: View {
  let weather: Weather

  var body: some View {
    VStack(spacing: 8) {
      if let url = URL(string: "https://openweathermap.org/img/wn/\(weather.icon)@2x.png") {
        AsyncImage(url: url) { image in
          image
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
        } placeholder: {
          ProgressView()
        }
      }

      // 場所情報を表示
      Text(weather.city)
        .font(.headline)
        .accessibility(identifier: "locationLabel")

      Text(weather.condition)
        .font(.headline)

      Text("\(weather.temperature, specifier: "%.1f")℃")
        .font(.title)
        .bold()
        .accessibility(identifier: "temperatureLabel")
    }
    .padding()
    .accessibility(identifier: "weatherView")
  }
}
