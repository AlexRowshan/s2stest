//
//  HomepageViewModel.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/2/24.
//

import SwiftUI

@MainActor
class HomepageViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var showCamera = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var navigateToImageView = false
    
    func handlePhotoCaptured(_ image: UIImage) {
        self.capturedImage = image
        self.navigateToImageView = true
    }
    
    func clearCapturedImage() {
        self.capturedImage = nil
        self.navigateToImageView = false
    }
}
