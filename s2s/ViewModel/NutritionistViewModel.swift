import Foundation
import Combine
import SwiftUI

class NutritionistViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var healthyRecipes: [RecipeModel] = []
    @Published var nutritionAnalysis: String = ""
    @Published var userInput: String = ""
    @Published var showRecipeGeneration = false
    @Published var generationCompleted = false
    @Published var nutritionistResponse: String = ""
    
    private let openAIService = OpenAIService()
    private var cancellables = Set<AnyCancellable>()
    
    private var recipeViewModel: RecipeViewModel
    
    init(recipeViewModel: RecipeViewModel) {
        self.recipeViewModel = recipeViewModel
    }
    
    // Add a method to update the recipeViewModel reference
    func updateRecipeViewModel(_ viewModel: RecipeViewModel) {
        self.recipeViewModel = viewModel
    }
    
    func generateHealthyRecipe(dietaryPreferences: String = "") {
        isLoading = true
        errorMessage = nil
        generationCompleted = false
        showRecipeGeneration = true
        
        let prompt = """
        You are a professional nutritionist. Create three different very healthy recipes that are nutritionally balanced.
        \(dietaryPreferences.isEmpty ? "" : "Consider these dietary preferences: \(dietaryPreferences)")
        
        Please generate the recipes in valid JSON format matching the following structure:
        [
          {
            "name": "Healthy Recipe Name",
            "duration": "Cooking Time in minutes",
            "difficulty": "Easy/Medium/Hard",
            "ingredients": ["Ingredient 1", "Ingredient 2", "..."],
            "instructions": ["Step 1", "Step 2", "..."],
            "nutritionalInfo": {
              "calories": "X calories per serving",
              "protein": "X g",
              "carbs": "X g",
              "fat": "X g",
              "fiber": "X g"
            },
            "healthBenefits": ["Benefit 1", "Benefit 2", "..."]
          },
          {
            // Second recipe with same structure
          },
          {
            // Third recipe with same structure
          }
        ]
        
        IMPORTANT: Ensure the JSON is valid and contains no additional text. Do not include the comment lines shown above in the second and third recipes - make them complete recipe objects.
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
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self = self,
                      let content = response.choices.first?.message.content else {
                    self?.errorMessage = "No response from nutritionist."
                    return
                }
                
                print("Received recipe response: \(content.prefix(100))") // Debug log
                self.parseHealthyRecipes(from: content)
                self.generationCompleted = true
            }
            .store(in: &cancellables)
    }
    
    func analyzeRecipe(_ recipe: RecipeModel) {
        isLoading = true
        errorMessage = nil
        nutritionAnalysis = ""
        
        let ingredients = recipe.ingredients.joined(separator: ", ")
        let instructions = recipe.instructions.joined(separator: ". ")
        
        let prompt = """
        As a professional nutritionist, analyze this recipe and provide a detailed, structured report with:
        
        1. BRIEF SUMMARY (1-2 sentences about overall nutritional profile)
        
        2. ESTIMATED MACRONUTRIENTS PER SERVING:
           - Calories: Approximately X calories
           - Protein: X g
           - Carbohydrates: X g
           - Fat: X g
           - Fiber: X g (if applicable)
        
        3. NUTRITIONAL STRENGTHS (what makes this recipe healthy)
           - List key nutritional benefits
           - Mention vitamins and minerals if possible
        
        4. AREAS FOR IMPROVEMENT
           - Practical suggestions to enhance nutritional value
           - Substitutions that could be made
        
        5. QUICK TIPS FOR MAKING IT HEALTHIER
           - 2-3 actionable changes
        
        Recipe: \(recipe.name)
        Ingredients: \(ingredients)
        Instructions: \(instructions)
        
        Format your response in clear sections with headers. Be specific with accurate numeric values for all macronutrients. Start with a very brief summary (1-2 sentences).
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
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self = self,
                      let content = response.choices.first?.message.content else {
                    self?.errorMessage = "No analysis received."
                    return
                }
                self.nutritionAnalysis = content
                
                // If the recipe doesn't have nutritional info, try to extract it from the analysis
                if recipe.nutritionalInfo == nil || recipe.nutritionalInfo?.isEmpty == true {
                    let extractedInfo = self.extractNutritionalInfo(from: content)
                    if !extractedInfo.isEmpty {
                        var updatedRecipe = recipe
                        updatedRecipe.nutritionalInfo = extractedInfo
                        
                        // Extract health benefits if possible
                        let extractedBenefits = self.extractHealthBenefits(from: content)
                        if !extractedBenefits.isEmpty {
                            updatedRecipe.healthBenefits = extractedBenefits
                        }
                        
                        // Note: updateRecipeWithNutrition method is commented out in your code
                        // self.recipeViewModel.updateRecipeWithNutrition(updatedRecipe)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func extractNutritionalInfo(from analysis: String) -> [String: String] {
        var nutritionalInfo: [String: String] = [:]
        
        // Look for the macronutrients section
        if let macroStart = analysis.range(of: "(ESTIMATED MACRONUTRIENTS|MACRONUTRIENTS|NUTRITIONAL INFORMATION)", options: [.regularExpression, .caseInsensitive]) {
            var macroSection = analysis[macroStart.lowerBound...]
            if let nextSection = macroSection.range(of: "(NUTRITIONAL STRENGTHS|STRENGTHS|AREAS FOR IMPROVEMENT)", options: [.regularExpression, .caseInsensitive]) {
                macroSection = macroSection[macroSection.startIndex..<nextSection.lowerBound]
            }
            
            // Extract calories
            if let caloriesRange = macroSection.range(of: "calories\\s*:.*?\\d+", options: [.regularExpression, .caseInsensitive]) {
                let calorieText = macroSection[caloriesRange]
                nutritionalInfo["calories"] = String(calorieText.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            // Extract other nutrients
            let nutrients = [
                ("protein", "protein\\s*:.*?\\d+\\s*g"),
                ("carbs", "(carbs|carbohydrates)\\s*:.*?\\d+\\s*g"),
                ("fat", "fat\\s*:.*?\\d+\\s*g"),
                ("fiber", "fiber\\s*:.*?\\d+\\s*g")
            ]
            
            for (key, pattern) in nutrients {
                if let range = macroSection.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                    let nutrientText = macroSection[range]
                    nutritionalInfo[key] = String(nutrientText.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        // If we haven't found structured data, try to extract with more generic patterns
        if nutritionalInfo.isEmpty {
            // Extract calories
            if let caloriesRange = analysis.range(of: "\\d+\\s*(calories|kcal)", options: .regularExpression) {
                let match = analysis[caloriesRange]
                nutritionalInfo["calories"] = String(match.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            // Extract macronutrients with generic patterns
            let nutrients = ["protein", "carbs", "fat", "fiber"]
            for nutrient in nutrients {
                let pattern = "\\d+\\s*g\\s*(of\\s*)?\(nutrient)"
                if let range = analysis.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                    let match = analysis[range]
                    nutritionalInfo[nutrient] = String(match.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        return nutritionalInfo
    }
    
    private func extractHealthBenefits(from analysis: String) -> [String] {
        var benefits: [String] = []
        
        // Look for strengths or benefits section
        if let strengthsStart = analysis.range(of: "(NUTRITIONAL STRENGTHS|STRENGTHS|HEALTH BENEFITS)", options: [.regularExpression, .caseInsensitive]) {
            var strengthsSection = analysis[strengthsStart.lowerBound...]
            if let nextSection = strengthsSection.range(of: "(AREAS FOR IMPROVEMENT|IMPROVEMENTS|QUICK TIPS)", options: [.regularExpression, .caseInsensitive]) {
                strengthsSection = strengthsSection[strengthsSection.startIndex..<nextSection.lowerBound]
            }
            
            // Extract bullet points if they exist
            let bulletPoints = strengthsSection.components(separatedBy: .newlines)
                .filter { line in
                    line.contains("-") || line.contains("•")
                }
                .map { line in
                    line.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "^\\s*(-|•)\\s*", with: "", options: .regularExpression)
                }
                .filter { !$0.isEmpty }
            
            benefits.append(contentsOf: bulletPoints)
        }
        
        return benefits
    }
    
    func answerNutritionQuestion(_ question: String) {
        isLoading = true
        errorMessage = nil
        nutritionistResponse = ""
        showRecipeGeneration = false
        
        let prompt = """
        You are a professional nutritionist. Answer the following nutrition-related question with expert knowledge but in a friendly, conversational tone. Provide practical advice when appropriate.
        
        Question: \(question)
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
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                guard let self = self,
                      let content = response.choices.first?.message.content else {
                    self?.errorMessage = "No response received."
                    return
                }
                self.nutritionistResponse = content
            }
            .store(in: &cancellables)
    }
    
    private func parseHealthyRecipes(from jsonString: String) {
        print("Parsing recipe JSON...")
        
        // Clean up the JSON string - extract just the JSON part
        var cleanedJson = jsonString
        
        if let startIndex = jsonString.range(of: "\\[\\s*\\{", options: .regularExpression)?.lowerBound,
           let endIndex = jsonString.range(of: "\\}\\s*\\]", options: .regularExpression)?.upperBound {
            cleanedJson = String(jsonString[startIndex..<endIndex])
            print("Extracted JSON between [ and ]: \(cleanedJson.prefix(50))...")
        } else {
            print("Could not find proper JSON boundaries")
        }
        
        // Additional cleanup - remove markdown code block markers if present
        cleanedJson = cleanedJson.replacingOccurrences(of: "```json", with: "")
        cleanedJson = cleanedJson.replacingOccurrences(of: "```", with: "")
        
        guard let data = cleanedJson.data(using: .utf8) else {
            self.errorMessage = "Failed to convert response to data."
            print("Failed to convert to data")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            var newRecipes = try decoder.decode([RecipeModel].self, from: data)
            print("Successfully decoded \(newRecipes.count) recipes")
            
            for i in 0..<newRecipes.count {
                newRecipes[i].userId = recipeViewModel.currentUserId
                newRecipes[i].id = UUID().uuidString
                
                // Ensure nutritional info exists
                if newRecipes[i].nutritionalInfo == nil {
                    newRecipes[i].nutritionalInfo = [:]
                }
                
                // Ensure health benefits exist
                if newRecipes[i].healthBenefits == nil {
                    newRecipes[i].healthBenefits = []
                }
                
                print("Recipe \(i): \(newRecipes[i].name)")
            }
            
            DispatchQueue.main.async {
                self.healthyRecipes = newRecipes
            }
        } catch {
            print("JSON parsing error: \(error)")
            
            // Try to fix common JSON issues and retry
            let fixedJson = fixCommonJsonIssues(jsonString: cleanedJson)
            
            if let fixedData = fixedJson.data(using: .utf8) {
                do {
                    let decoder = JSONDecoder()
                    var newRecipes = try decoder.decode([RecipeModel].self, from: fixedData)
                    print("Successfully decoded \(newRecipes.count) recipes after fixing JSON")
                    
                    for i in 0..<newRecipes.count {
                        newRecipes[i].userId = recipeViewModel.currentUserId
                        newRecipes[i].id = UUID().uuidString
                    }
                    
                    DispatchQueue.main.async {
                        self.healthyRecipes = newRecipes
                    }
                } catch {
                    self.errorMessage = "Failed to parse recipes: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "Failed to parse recipes: \(error.localizedDescription)"
            }
        }
    }
    
    // Helper to fix common JSON issues
    private func fixCommonJsonIssues(jsonString: String) -> String {
        var fixed = jsonString
        
        // Replace single quotes with double quotes
        fixed = fixed.replacingOccurrences(of: "'", with: "\"")
        
        // Ensure array brackets are present
        if !fixed.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("[") {
            fixed = "[\(fixed)"
        }
        if !fixed.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("]") {
            fixed = "\(fixed)]"
        }
        
        return fixed
    }
    
    func saveRecipeToUserCollection(_ recipe: RecipeModel) {
        recipeViewModel.addRecipes([recipe])
    }
}
