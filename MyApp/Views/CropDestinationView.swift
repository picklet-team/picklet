// CropDestinationView.swift
import SwiftUI

struct CropDestinationView: View {
    let selectedImage: UIImage?
    @EnvironmentObject var viewModel: ClothingViewModel

    var body: some View {
        if let selected = selectedImage {
            ClothingCropEditView(originalImage: selected) { croppedImage in
                Task {
                    do {
                        let url = try await SupabaseService.shared.uploadImage(croppedImage, for: UUID().uuidString)
                        _ = await viewModel.updateTemporaryClothing(with: url)
                        await viewModel.loadClothes()
                    } catch {
                        print("❌ アップロード失敗: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            EmptyView()
        }
    }
}
