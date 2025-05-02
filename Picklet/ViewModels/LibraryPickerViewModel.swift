//
//  LibraryPickerViewModel.swift
//  MyApp
//
//  Created by al dente on 2025/04/30.
//

import Combine
// ViewModels/LibraryPickerViewModel.swift
import SwiftUI

@MainActor
final class LibraryPickerViewModel: ObservableObject {
  @Published var urls: [URL] = []

  private var cancellables = Set<AnyCancellable>()
  private let imageStorageService = ImageStorageService.shared

  func fetch() {
    Task {
      do {
        self.urls = try await imageStorageService.listClothingImageURLs()
      } catch {
        print("❌ image fetch error:", error)
      }
    }
  }
}
