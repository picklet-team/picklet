//
//  CameraPreviewView.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import AVFoundation
import SwiftUI

struct CameraPreviewView: UIViewControllerRepresentable {
  var onImageCaptured: (UIImage) -> Void
  class Coordinator {
    var controller: CameraPreviewController?
  }

  @Binding var triggerCapture: Bool

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  func makeUIViewController(context: Context) -> CameraPreviewController {
    let controller = CameraPreviewController()
    controller.onImageCaptured = onImageCaptured
    context.coordinator.controller = controller
    return controller
  }

  func updateUIViewController(_ uiViewController: CameraPreviewController, context: Context) {
    if triggerCapture {
      uiViewController.capture()
      DispatchQueue.main.async {
        triggerCapture = false // reset after shot
      }
    }
  }
}
