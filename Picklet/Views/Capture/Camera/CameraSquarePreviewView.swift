//
//  CameraSquarePreviewView.swift
//  Picklet
//
//  Created by al dente on 2025/04/30.
//

import SwiftUI

struct CameraSquarePreviewView: View {
  let onCaptured: (UIImage) -> Void
  @State private var shouldCapture = false

  var body: some View {
    GeometryReader { geo in
      let size = min(geo.size.width, geo.size.height)

      ZStack {
        CameraPreviewView(onImageCaptured: onCaptured, triggerCapture: $shouldCapture)
          .frame(width: size, height: size)
          .clipped()

        VStack {
          Spacer()
          Button(action: {
            shouldCapture = true
          }, label: {
            Circle()
              .fill(Color.white)
              .frame(width: 70, height: 70)
              .shadow(radius: 4)
          })
          .padding(.bottom, 40)
        }
      }
    }
  }
}
