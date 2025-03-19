import Foundation
import Combine
import UIKit
import CloudKit

class RecipeViewModel: ObservableObject {
    @Published var recipes: [RecipeModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var generationCompleted = false
    @Published var generationStarted = false

    
    private let appState: AppState
    private let openAIService = OpenAIService()
    private var cancellables = Set<AnyCancellable>()
    
    private let cloudDatabase = CKContainer.default().publicCloudDatabase
    
    init(appState: AppState) {
        self.appState = appState
        loadRecipes()
        loadRecipesFromCloud()
    }
    
    var currentUserId: String {
        return appState.currentUserID ?? ""
    }

    
    
    func loadRecipes() {
        guard let userId = appState.currentUserID else {
            recipes = []
            return
        }
        if let data = UserDefaults.standard.data(forKey: "recipes_\(userId)") {
            do {
                let decoded = try JSONDecoder().decode([RecipeModel].self, from: data)
                recipes = decoded.filter { $0.userId == userId }
            } catch {
                print("Error decoding recipes: \(error)")
                recipes = []
            }
        }
    }
    
    private func saveRecipes() {
        guard let userId = appState.currentUserID else { return }
        do {
            let encoded = try JSONEncoder().encode(recipes)
            UserDefaults.standard.set(encoded, forKey: "recipes_\(userId)")
        } catch {
            print("Error saving recipes: \(error)")
        }
    }
    
    
    func loadRecipesFromCloud() {
        guard let currentUser = appState.currentUserID else { return }
        let predicate = NSPredicate(format: "userId == %@", currentUser)
        let query = CKQuery(recordType: "Recipe", predicate: predicate)
        
        cloudDatabase.perform(query, inZoneWith: nil) { records, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "CloudKit Error: \(error.localizedDescription)"
                    return
                }
                if let records = records {
                    let cloudRecipes = records.map { RecipeModel(record: $0) }
                    self.recipes = cloudRecipes
                    self.saveRecipes()
                }
            }
        }
    }

        
    func addRecipes(_ recipes: [RecipeModel]) {
        DispatchQueue.main.async {
            self.recipes.append(contentsOf: recipes)
            self.saveRecipes()
            self.objectWillChange.send() // Ensure UI updates
            for recipe in recipes {
                self.saveRecipeToCloud(recipe)
            }
        }
    }

    func saveRecipeToCloud(_ recipe: RecipeModel) {
        let record = recipe.toRecord()
        cloudDatabase.save(record) { (savedRecord, error) in
            DispatchQueue.main.async {
                if let error = error {
                    if error.localizedDescription.contains("already exists") {
                        print("Record already exists, skipping duplicate save.")
                    } else {
                        self.errorMessage = "CloudKit error: \(error.localizedDescription)"
                    }
                } else {
                    print("Successfully saved recipe to CloudKit")
                }
            }
        }
    }



        
        func deleteRecipe(at offsets: IndexSet) {
            for index in offsets {
                let recipe = recipes[index]
                let recordID = CKRecord.ID(recordName: recipe.id)
                cloudDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            self.errorMessage = error.localizedDescription
                        }
                    }
                }
            }
            recipes.remove(atOffsets: offsets)
            saveRecipes()
        }
    
        func delete(recipe: RecipeModel) {
            if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
                deleteRecipe(at: IndexSet(integer: index))
            }
        }

        
//        func generateRecipesFromImage(_ image: UIImage) {
////            let resizedImage : UIImage = openAIService.resizeImage(image: image, targetWidth: 128) ?? image
////            guard let base64Image = resizedImage.jpegData(compressionQuality: 0.5)?.base64EncodedString() else {
////                self.errorMessage = "Failed to encode image."
////                return
////            }
//            
//            isLoading = true
//            errorMessage = nil
//            
//            openAIService.sendImageMessage(base64Image: base64Image)
//                .receive(on: DispatchQueue.main)
//                .sink { [weak self] completion in
//                    self?.isLoading = false
//                    if case .failure(let error) = completion {
//                        self?.errorMessage = error.localizedDescription
//                    }
//                } receiveValue: { [weak self] response in
//                    guard let self = self,
//                          let content = response.choices.first?.message.content else {
//                        self?.errorMessage = "No response from GPT."
//                        return
//                    }
//                    self.parseRecipes(from: content)
//                    print("CONTENT RIGHT HEREEEE BRUHHHHH: \(content)")
//                }
//                .store(in: &cancellables)
//        }
    

    func generateRecipesFromImage(_ image: UIImage) {
        guard let base64Image = image.jpegData(compressionQuality: 0.8)?.base64EncodedString() else {
            self.errorMessage = "Failed to encode image."
            return
        }
        
        isLoading = true
        errorMessage = nil
        generationStarted = true
        generationCompleted = false
        
        openAIService.sendImageMessage(base64Image: base64Image)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to process receipt: \(error.localizedDescription)"
                    self?.generationCompleted = true
                }
            } receiveValue: { [weak self] response in
                guard let self = self,
                      let content = response.choices.first?.message.content else {
                    self?.errorMessage = "Could not read items from receipt. Please try again or enter ingredients manually."
                    self?.generationCompleted = true
                    return
                }
                
                do {
                    self.parseRecipes(from: content)
                    self.generationCompleted = true
                } catch {
                    self.errorMessage = "Could not create recipe from receipt. Try entering ingredients manually."
                    self.generationCompleted = true
                }
            }
            .store(in: &cancellables)
    }

    func generateRecipesFromChat(ingredients: [String], allergyText: String) {
        isLoading = true
        errorMessage = nil
        generationStarted = true
        generationCompleted = false
        
        // Ensure we have ingredients
        guard !ingredients.isEmpty else {
            errorMessage = "Please add at least one ingredient."
            isLoading = false
            generationCompleted = true
            return
        }
        
        let ingredientsList = ingredients.joined(separator: ", ")
        let prompt = """
        Create a combined list of the following ingredients along with common household ingredients: \(ingredientsList).
        Exclude any ingredients that conflict with the following allergies: \(allergyText).
        Now, please generate an array of 1 recipe in JSON format matching the following structure:
        [
          {
            "name": "Recipe Name",
            "duration": "Cooking Time in minutes",
            "difficulty": "Easy/Medium/Hard",
            "ingredients": ["Ingredient 1", "Ingredient 2", ...],
            "instructions": ["Step 1", "Step 2", ...]
          }
        ]
        Ensure that the JSON is valid and contains no additional text.
        """
        
        let message = ChatMessage(
            id: UUID().uuidString,
            content: prompt,
            dateCreated: Date(),
            sender: .me
        )
        
        openAIService.sendMessage(messages: [message])
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to generate recipe: \(error.localizedDescription)"
                    self?.generationCompleted = true
                }
            } receiveValue: { [weak self] response in
                guard let self = self,
                      let content = response.choices.first?.message.content else {
                    self?.errorMessage = "Could not generate a recipe. Please try different ingredients."
                    self?.generationCompleted = true
                    return
                }
                
                do {
                    self.parseRecipes(from: content)
                    self.generationCompleted = true
                } catch {
                    self.errorMessage = "Could not create recipe from ingredients. Please try again."
                    self.generationCompleted = true
                }
            }
            .store(in: &cancellables)
    }

    private func parseRecipes(from jsonString: String) {
        var cleanedJsonString = jsonString
        
        // Try to extract JSON if it's wrapped in code blocks or has extra text
        if let jsonStartIndex = jsonString.range(of: "[{")?.lowerBound,
           let jsonEndIndex = jsonString.range(of: "}]", options: .backwards)?.upperBound {
            cleanedJsonString = String(jsonString[jsonStartIndex..<jsonEndIndex])
        }
        
        guard let data = cleanedJsonString.data(using: .utf8) else {
            self.errorMessage = "Failed to convert response to data."
            return
        }
        
        do {
            let decoder = JSONDecoder()
            var newRecipes = try decoder.decode([RecipeModel].self, from: data)
            
            // Debug: print the current user id
            print("Current user id: \(appState.currentUserID ?? "nil")")
            
            for i in 0..<newRecipes.count {
                newRecipes[i].userId = appState.currentUserID ?? ""
                newRecipes[i].id = UUID().uuidString
            }
            
            DispatchQueue.main.async {
                self.recipes.append(contentsOf: newRecipes)
                self.saveRecipes()
            }
            
            for recipe in newRecipes {
                self.saveRecipeToCloud(recipe)
            }
        } catch {
            self.errorMessage = "Failed to parse recipes: \(error.localizedDescription)"
        }
    }

    }
