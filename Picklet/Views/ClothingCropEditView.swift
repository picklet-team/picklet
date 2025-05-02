//
//  ClothingCropEditView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI
import Photos

struct ClothingCropEditView: View {
  let originalImage: UIImage
  let onComplete: (UIImage) -> Void

  @State private var userMaskImage = UIImage()
  @State private var currentPenColor = UIColor.white

  @Environment(\.dismiss) private var dismiss

  @State private var maskedImage: UIImage?
  @State private var isLoading = true
  @State private var isShowingAlert = false
  @State private var alertTitle = ""
  @State private var alertMessage = ""

  @StateObject private var canvasCoordinator = MaskEditCanvasView.Coordinator()

  var body: some View {
    VStack {
      if isLoading {
        ProgressView("AIが服を切り抜いています…")
          .padding()
      } else if let result = maskedImage {
        ZStack {
          Image(uiImage: result)
            .resizable()
            .scaledToFit()
            .padding()

          MaskEditCanvasView(drawingImage: $userMaskImage, penColor: currentPenColor, penWidth: 20)
            .frame(width: 300, height: 400)
            .background(Color.clear)
            .environmentObject(canvasCoordinator)
        }

        HStack {
          Button("保存") {
            saveMaskToPhotoLibrary()
          }
          .padding()
          .buttonStyle(.bordered)
          
          Button("登録する") {
            let exportedMask = canvasCoordinator.exportDrawingImage()
            onComplete(exportedMask)
            dismiss()
          }
          .padding()
        }
      } else {
        Text("切り抜きに失敗しました")
        Button("戻る") {
          dismiss()
        }
        .padding()
      }
    }
    .navigationTitle("画像編集")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await processImage()
    }
    .alert(alertTitle, isPresented: $isShowingAlert) {
      Button("OK") {}
    } message: {
      Text(alertMessage)
    }
  }

  private func processImage() async {
    if let output = await CoreMLService.shared.processImage(image: originalImage) {
      self.maskedImage = output
    }
    self.isLoading = false
  }
  
  private func saveMaskToPhotoLibrary() {
    let exportedMask = canvasCoordinator.exportDrawingImage()
    
    UIImageWriteToSavedPhotosAlbum(exportedMask, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
  }
  
  @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
    if let error = error {
      showAlert(title: "保存エラー", message: error.localizedDescription)
    } else {
      showAlert(title: "保存完了", message: "マスク画像が保存されました")
    }
  }
  
  private func showAlert(title: String, message: String) {
    alertTitle = title
    alertMessage = message
    isShowingAlert = true
  }
}
