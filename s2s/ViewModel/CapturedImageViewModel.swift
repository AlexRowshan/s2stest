//import Foundation
//import Combine
//import UIKit
//import CloudKit
//
//class CapturedImageViewModel: ObservableObject {
//    @Published var generatedText: String = ""
//    @Published var isLoading: Bool = false
//    @Published var errorMessage: String? = nil
//    @Published var recipes: [RecipeModel] = []
//    private var hasProcessedImage = false
//    
//    private var cancellables = Set<AnyCancellable>()
//    
//    private let cloudDatabase = CKContainer.default().publicCloudDatabase
//    
//    private let currentUserId: String = "currentUserID_placeholder"
//    
//    private let recipeViewModel: RecipeViewModel
//
//    init(recipeViewModel : RecipeViewModel) {
//        self.recipeViewModel = recipeViewModel
//    }
//    
//    func processImage(image: UIImage) {
//        guard !hasProcessedImage else { return }
//        hasProcessedImage = true
//        let openAIService = OpenAIService()
//        
////        let resizedImage : UIImage = openAIService.resizeImage(image: image, targetWidth: 128) ?? image
//        guard let base64Image = encodeImageToBase64(image: image) else {
//            self.errorMessage = "Failed to encode image."
//            self.isLoading = false
//            return
//            
//        }
//
//        self.isLoading = true
//        self.errorMessage = nil
//        self.recipes = []
//        openAIService.sendImageMessage(base64Image: base64Image)
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] completion in
//                self?.isLoading = false
//                switch completion {
//                case .failure(let error):
//                    print("API Error: \(error.localizedDescription)")
//                    self?.errorMessage = error.localizedDescription
//                case .finished:
//                    print("API request completed")
//                }
//            } receiveValue: { [weak self] response in
//                guard let self = self else { return }
//                
//                if let content = response.choices.first?.message.content {
//                    print("Received content: \(content)")
//                    self.generatedText = content
//                    self.parseRecipes(from: content)
//                } else {
//                    self.errorMessage = "No response from GPT."
//                }
//                self.isLoading = false
//            }
//            .store(in: &cancellables)
//    }
//    
//    func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage? {
//        let scale = targetWidth / image.size.width
//        let targetHeight = image.size.height * scale
//        let newSize = CGSize(width: targetWidth, height: targetHeight)
//        
//        let renderer = UIGraphicsImageRenderer(size: newSize)
//        return renderer.image { _ in
//            image.draw(in: CGRect(origin: .zero, size: newSize))
//        }
//    }
//
//
//    func compressImageToTargetSize(image: UIImage, targetByteSize: Int) -> Data? {
//        // Set an initial target raw size (accounting for ~33% base64 overhead)
//        let targetRawSize = Int(Double(targetByteSize) * 0.75)
//        
//        // Start with the image at a defined maximum width (e.g., 1024)
//        var currentImage = image
//        var compressionQuality: CGFloat = 0.5
//        guard var imageData = currentImage.jpegData(compressionQuality: compressionQuality) else {
//            return nil
//        }
//        
//        // First, try lowering the JPEG quality only.
//        while imageData.count > targetRawSize && compressionQuality > 0.1 {
//            compressionQuality -= 0.1
//            if let compressedData = currentImage.jpegData(compressionQuality: compressionQuality) {
//                imageData = compressedData
//            } else {
//                break
//            }
//        }
//        
//        // If the image is still too large, reduce its dimensions and try again.
//        while imageData.count > targetRawSize && currentImage.size.width > 256 {
//            // Reduce the width by 20%
//            let newWidth = currentImage.size.width * 0.8
//            if let resizedImage = resizeImage(image: currentImage, targetWidth: newWidth) {
//                currentImage = resizedImage
//                // Reset quality for the resized image.
//                compressionQuality = 0.9
//                if let newData = currentImage.jpegData(compressionQuality: compressionQuality) {
//                    imageData = newData
//                } else {
//                    break
//                }
//                // Again, try lowering the quality if needed.
//                while imageData.count > targetRawSize && compressionQuality > 0.1 {
//                    compressionQuality -= 0.1
//                    if let compressedData = currentImage.jpegData(compressionQuality: compressionQuality) {
//                        imageData = compressedData
//                    } else {
//                        break
//                    }
//                }
//            } else {
//                break
//            }
//        }
//        
//        if imageData.count > targetRawSize {
//            print("Warning: Unable to compress image below \(targetRawSize) bytes without extreme quality loss.")
//        }
//        
//        return imageData
//    }
//
//
//
//
//    private func encodeImageToBase64(image: UIImage) -> String? {
//        if let compressedData = compressImageToTargetSize(image: image, targetByteSize: 135000) {
//            let base64Image = compressedData.base64EncodedString()
//            return base64Image
//            // Use `base64Image` in your request payload.
//        } else {
//////        if let resizedImage = resizeImage(image: image, targetWidth: 1024) ?? image {
////            return resizeimage
//            return "Failed to compress image."
//        }
//
////        guard let imageData = compressedData.jpegData(compressionQuality: 0.5) else {
////            print("Failed to create JPEG data")
////            return nil
////        }
////        return imageData.base64EncodedString()
//    }
//    
//    private func parseRecipes(from jsonString: String) {
//        print("Attempting to parse JSON: \(jsonString)")
//        
//        guard let jsonData = jsonString.data(using: .utf8) else {
//            print("Failed to convert string to data")
//            self.errorMessage = "Failed to convert response to data."
//            return
//        }
//        
//        do {
//            let decoder = JSONDecoder()
//            var newRecipes = try decoder.decode([RecipeModel].self, from: jsonData)
//            print("Successfully parsed \(newRecipes.count) recipes")
//            
//            for i in 0..<newRecipes.count {
//                newRecipes[i].userId = recipeViewModel.currentUserId
//                newRecipes[i].id = UUID().uuidString
//            }
//
//            DispatchQueue.main.async {
//                self.recipeViewModel.addRecipes(newRecipes)
//                self.recipes.append(contentsOf: newRecipes)
//            }
//        } catch {
//            print("JSON parsing error: \(error)")
//            self.errorMessage = "Failed to parse recipes: \(error.localizedDescription)"
//        }
//    }
//
//    
//    private func saveRecipeToCloud(_ recipe: RecipeModel) {
//        let record = recipe.toRecord()
//        cloudDatabase.save(record) { (savedRecord, error) in
//            DispatchQueue.main.async {
//                if let error = error {
//                    print("CloudKit saving error: \(error.localizedDescription)")
//                    self.errorMessage = "CloudKit error: \(error.localizedDescription)"
//                } else {
//                    print("Successfully saved recipe to CloudKit")
//                }
//            }
//        }
//    }
//}
import SwiftUI
import Combine

class CapturedImageViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var recipes: [RecipeModel] = []
    
    private let recipeViewModel: RecipeViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(recipeViewModel: RecipeViewModel) {
        self.recipeViewModel = recipeViewModel
        
        recipeViewModel.$recipes
            .sink { [weak self] recipes in
                self?.recipes = recipes
            }
            .store(in: &cancellables)
        
        recipeViewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] errorMessage in
                self?.errorMessage = errorMessage
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }
    
    func processImage(image: UIImage) {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.recipeViewModel.generateRecipesFromImage(image)
        }
    }
}
