//
//  ModeSwitchBarView.swift
//  Picklet
//
//  Created by al dente on 2025/04/30.
//

import SwiftUI

struct ModeSwitchBarView: View {
  let isCameraSelected: Bool
  let onCamera: () -> Void
  let onLibrary: () -> Void

  var body: some View {
    HStack {
      modeButton(icon: "camera", title: "カメラ", isSelected: isCameraSelected, action: onCamera)
        .accessibility(identifier: "cameraButton")

      modeButton(
        icon: "photo.on.rectangle", title: "ライブラリ", isSelected: !isCameraSelected, action: onLibrary
      )
      .accessibility(identifier: "libraryButton")
    }
    .padding()
    .background(Color(UIColor.systemBackground))
  }

  private func modeButton(
    icon: String, title: String, isSelected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      VStack {
        Image(systemName: icon)
          .font(.title)
        //                Text(title)
      }
      .foregroundColor(isSelected ? .blue : .gray)
      .frame(maxWidth: .infinity)
    }
  }
}
