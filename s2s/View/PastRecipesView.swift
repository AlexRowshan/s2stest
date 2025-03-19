//
//  PastRecipesView.swift
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//

import SwiftUI

import SwiftUI

struct PastRecipesView: View {
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    @EnvironmentObject var appState: AppState
    
    @StateObject private var nutritionistViewModel = NutritionistViewModel(recipeViewModel: RecipeViewModel(appState: AppState()))
    
    @State private var expandedRecipeID: String? = nil
    @State private var selectedRecipeForAnalysis: RecipeModel? = nil
    @State private var initialLoad = true
    @State private var isRefreshing = false
    @State private var showAnalysis = false
    
    var userRecipes: [RecipeModel] {
        guard let currentUser = appState.currentUserID, !currentUser.isEmpty else { return [] }
        
        // Sort recipes by ID in descending order (newer IDs should be larger)
        // This ensures newest recipes appear first
        return recipeViewModel.recipes
            .filter { $0.userId == currentUser }
            .sorted(by: { $0.id > $1.id })
    }
    
    // Alternate colors for recipe cards
    let cardColors = [Color(hex: "#F1F8E9"), Color(hex: "#E8F5E9"), Color(hex: "#DCEDC8")]
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#8AC36F"), Color.white]),
                           startPoint: .top,
                           endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 16) {
                    if userRecipes.isEmpty {
                        Text("No recipes found for your account.")
                            .foregroundColor(.white)
                            .padding()
                    } else {
                        ForEach(Array(userRecipes.enumerated()), id: \.element.id) { index, recipe in
                            RecipeCard(
                                recipe: recipe,
                                isExpanded: expandedRecipeID == recipe.id,
                                backgroundColor: cardColors[index % cardColors.count],
                                onToggleExpand: {
                                    withAnimation {
                                        expandedRecipeID = (expandedRecipeID == recipe.id) ? nil : recipe.id
                                    }
                                },
                                onDeleteRecipe: {
                                    recipeViewModel.delete(recipe: recipe)
                                },
                                onAnalyzeRecipe: {
                                    selectedRecipeForAnalysis = recipe
                                    nutritionistViewModel.analyzeRecipe(recipe)
                                    showAnalysis = true
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            
            if nutritionistViewModel.isLoading {
                LoadingIndicator()
            }
            
            if showAnalysis, let recipe = selectedRecipeForAnalysis {
                RecipeAnalysisView(
                    recipe: recipe,
                    analysis: nutritionistViewModel.nutritionAnalysis,
                    isPresented: $showAnalysis
                )
            }
        }
        .navigationTitle("My Recipes")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isRefreshing = true
                    recipeViewModel.loadRecipesFromCloud()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isRefreshing = false
                    }
                } label: {
                    if isRefreshing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { recipeViewModel.errorMessage != nil },
            set: { _ in recipeViewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(recipeViewModel.errorMessage ?? "")
        }
        .onAppear {
            // Only expand the newest recipe when the view first appears
            if initialLoad && !userRecipes.isEmpty {
                expandedRecipeID = userRecipes.first?.id
                initialLoad = false
            }
        }
        .onChange(of: recipeViewModel.recipes.count) { _ in
            // If new recipes are added, expand the newest one
            if !userRecipes.isEmpty {
                expandedRecipeID = userRecipes.first?.id
            }
        }
    }
}
        struct RecipeCard: View {
            let recipe: RecipeModel
            let isExpanded: Bool
            let backgroundColor: Color
            let onToggleExpand: () -> Void
            let onDeleteRecipe: () -> Void
            let onAnalyzeRecipe: () -> Void
            
            var body: some View {
                VStack(alignment: .leading, spacing: 0) {
                    // Recipe header (always visible)
                    Button(action: onToggleExpand) {
                        HStack {
                            Text(recipe.name)
                                .font(.custom("Avenir", size: 18))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color(hex: "#7cd16b"))
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            onDeleteRecipe()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    
                    // Expanded content
                    if isExpanded {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration: \(recipe.duration)")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(Color(hex: "#2E7D32"))
                                Spacer()
                                Text("Difficulty: \(recipe.difficulty)")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(Color(hex: "#2E7D32"))
                            }
                            
                            Divider()
                                .background(Color(hex: "#7cd16b").opacity(0.5))
                            
                            Text("Ingredients:")
                                .font(.custom("Avenir", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#2E7D32"))
                            
                            ForEach(recipe.ingredients, id: \.self) { ingredient in
                                Text("• \(ingredient)")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(.black)
                            }
                            
                            Divider()
                                .background(Color(hex: "#7cd16b").opacity(0.5))
                            
                            Text("Instructions:")
                                .font(.custom("Avenir", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "#2E7D32"))
                            
                            ForEach(Array(zip(recipe.instructions.indices, recipe.instructions)), id: \.0) { index, instruction in
                                Text("\(index + 1). \(instruction)")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(.black)
                                    .padding(.bottom, 2)
                            }
                            
                            // Analyze button
                            Button(action: onAnalyzeRecipe) {
                                HStack {
                                    Image(systemName: "chart.bar")
                                    Text("Analyze Nutrition")
                                }
                                .font(.custom("Avenir", size: 14))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color(hex: "#7cd16b"))
                                .cornerRadius(8)
                                .padding(.top, 5)
                            }
                        }
                        .padding()
                        .background(backgroundColor)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
        }
        
        struct LoadingIndicator: View {
            var body: some View {
                ZStack {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#7cd16b")))
                            .scaleEffect(2)
                        
                        Text("Analyzing Recipe...")
                            .font(.custom("Avenir", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 20)
                    }
                    .padding(30)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(15)
                    .shadow(radius: 10)
                }
            }
        }
        
        
        struct RecipeAnalysisView: View {
            let recipe: RecipeModel
            let analysis: String
            @Binding var isPresented: Bool
            
            // Extract nutrition values for visualization
            private var nutritionValues: [String: Double] {
                var values: [String: Double] = [:]
                
                // First try to get nutrition from recipe.nutritionalInfo if available
                if let nutritionalInfo = recipe.nutritionalInfo {
                    for (key, value) in nutritionalInfo {
                        if key.lowercased().contains("calorie") {
                            let calorieString = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let calories = Double(calorieString) {
                                values["calories"] = calories
                            }
                        } else if key.lowercased().contains("protein") {
                            let proteinString = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let protein = Double(proteinString) {
                                values["protein"] = protein
                            }
                        } else if key.lowercased().contains("carb") {
                            let carbString = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let carbs = Double(carbString) {
                                values["carbs"] = carbs
                            }
                        } else if key.lowercased().contains("fat") {
                            let fatString = value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                            if let fat = Double(fatString) {
                                values["fat"] = fat
                            }
                        }
                    }
                }
                
                // If we still need values, try to extract from analysis text
                if !analysis.isEmpty {
                    // Parse calories if not already set
                    if values["calories"] == nil {
                        // Try various patterns for calories
                        let caloriePatterns = [
                            "\\b\\d+\\s*calories\\b",
                            "calories\\s*:\\s*\\d+",
                            "approximately\\s*\\d+\\s*calories",
                            "about\\s*\\d+\\s*calories"
                        ]
                        
                        for pattern in caloriePatterns {
                            if let caloriesRange = analysis.range(of: pattern, options: .regularExpression) {
                                let caloriesString = analysis[caloriesRange].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                                if let calories = Double(caloriesString) {
                                    values["calories"] = calories
                                    break
                                }
                            }
                        }
                    }
                    
                    // Parse macronutrients (protein, carbs, fat) if not already set
                    let nutrients = ["protein", "carbs", "carbohydrates", "fat"]
                    for nutrient in nutrients {
                        let nutrientKey = nutrient == "carbohydrates" ? "carbs" : nutrient
                        
                        if values[nutrientKey] == nil {
                            // Try various patterns for each nutrient
                            let patterns = [
                                "\\b\\d+(\\.\\d+)?\\s*(g|grams)\\s*of\\s*\(nutrient)\\b",
                                "\\b\(nutrient)\\s*:\\s*\\d+(\\.\\d+)?\\s*(g|grams)\\b",
                                "\\b\(nutrient)\\s*content\\s*is\\s*\\d+(\\.\\d+)?\\s*(g|grams)\\b",
                                "\\b\(nutrient)\\s*\\(\\s*\\d+(\\.\\d+)?\\s*(g|grams)\\s*\\)",
                                "\\b\(nutrient)\\s*–\\s*\\d+(\\.\\d+)?\\s*(g|grams)\\b"
                            ]
                            
                            for pattern in patterns {
                                if let range = analysis.range(of: pattern, options: .regularExpression) {
                                    let match = String(analysis[range])
                                    let numberString = match.components(separatedBy: CharacterSet.decimalDigits.union(CharacterSet(charactersIn: "."))).joined(separator: "")
                                    if let value = Double(numberString) {
                                        values[nutrientKey] = value
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
                
                return values
            }
            
            // Get a detailed analysis summary including strengths and suggestions
            private var analysisSummary: String {
                if analysis.isEmpty {
                    return "Analyzing recipe..."
                }
                
                var summary = ""
                
                // Try to extract the brief summary (first 1-2 sentences)
                if let introEnd = analysis.range(of: "(\\.|\\n)\\s", options: .regularExpression) {
                    let firstSentence = analysis[analysis.startIndex..<introEnd.upperBound]
                    summary += "Overview: " + String(firstSentence) + "\n\n"
                }
                
                // Extract nutritional strengths section
                if let strengthsStart = analysis.range(of: "\\b(strengths|nutritional strengths|health benefits)\\b", options: [.regularExpression, .caseInsensitive]) {
                    var strengthsText = analysis[strengthsStart.lowerBound...]
                    if let nextSection = strengthsText.range(of: "\\n\\n|\\b(areas|improvements|suggestions)\\b", options: [.regularExpression, .caseInsensitive]) {
                        strengthsText = strengthsText[strengthsText.startIndex..<nextSection.lowerBound]
                    }
                    summary += "Strengths: " + String(strengthsText) + "\n\n"
                }
                
                // Extract suggestions/improvements section
                if let suggestionsStart = analysis.range(of: "\\b(suggestions|improvements|areas for improvement)\\b", options: [.regularExpression, .caseInsensitive]) {
                    var suggestionsText = analysis[suggestionsStart.lowerBound...]
                    if let nextSection = suggestionsText.range(of: "\\n\\n|conclusion", options: [.regularExpression, .caseInsensitive]) {
                        suggestionsText = suggestionsText[suggestionsText.startIndex..<nextSection.lowerBound]
                    }
                    summary += "Improvements: " + String(suggestionsText)
                }
                
                return summary.isEmpty ? "Analysis completed, but no specific recommendations were extracted." : summary
            }
            
            // Get a description for each nutrition metric
            private func getNutritionDescription(for nutrient: String, value: Double) -> String {
                switch nutrient {
                case "calories":
                    if value < 300 {
                        return "Low calorie meal (< 300 calories) - Good for weight loss"
                    } else if value < 600 {
                        return "Moderate calorie meal (300-600 calories) - Balanced for most adults"
                    } else {
                        return "Higher calorie meal (> 600 calories) - Better for active individuals"
                    }
                case "protein":
                    if value < 15 {
                        return "Low protein (< 15g) - May need supplementing for muscle maintenance"
                    } else if value < 30 {
                        return "Moderate protein (15-30g) - Adequate for most adults"
                    } else {
                        return "High protein (> 30g) - Great for muscle building and satiety"
                    }
                case "carbs":
                    if value < 30 {
                        return "Low carb (< 30g) - Suitable for ketogenic or low-carb diets"
                    } else if value < 60 {
                        return "Moderate carbs (30-60g) - Balanced energy source"
                    } else {
                        return "Higher carbs (> 60g) - Good for athletes and active individuals"
                    }
                case "fat":
                    if value < 10 {
                        return "Low fat (< 10g) - May lack essential fatty acids"
                    } else if value < 25 {
                        return "Moderate fat (10-25g) - Good balance for most diets"
                    } else {
                        return "Higher fat (> 25g) - Energy dense, check saturated fat content"
                    }
                default:
                    return ""
                }
            }
            
            var body: some View {
                ZStack {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            isPresented = false
                        }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        // Header
                        HStack {
                            Text("Nutritional Analysis")
                                .font(.custom("Avenir", size: 20))
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                isPresented = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.bottom, 5)
                        
                        // Recipe name
                        Text(recipe.name)
                            .font(.custom("Avenir", size: 18))
                            .fontWeight(.semibold)
                            .padding(.bottom, 5)
                        
                        Divider()
                        
                        if analysis.isEmpty {
                            // Loading indicator
                            HStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(1.5)
                                    .padding()
                                Spacer()
                            }
                        } else {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 15) {
                                    // Nutrition visualization
                                    VStack(spacing: 15) {
                                        Text("Nutrition Breakdown")
                                            .font(.custom("Avenir", size: 16))
                                            .fontWeight(.bold)
                                        
                                        // Calorie bar
                                        if let calories = nutritionValues["calories"], calories > 0 {
                                            VStack(alignment: .leading, spacing: 2) {
                                                NutritionBar(
                                                    label: "Calories",
                                                    value: "\(Int(calories))",
                                                    percentage: min(calories / 1000, 1.0),
                                                    color: Color(hex: "#FFC107")
                                                )
                                                
                                                Text(getNutritionDescription(for: "calories", value: calories))
                                                    .font(.custom("Avenir", size: 12))
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                        
                                        // Protein bar
                                        if let protein = nutritionValues["protein"], protein > 0 {
                                            VStack(alignment: .leading, spacing: 2) {
                                                NutritionBar(
                                                    label: "Protein",
                                                    value: "\(Int(protein))g",
                                                    percentage: min(protein / 50, 1.0),
                                                    color: Color(hex: "#4CAF50")
                                                )
                                                
                                                Text(getNutritionDescription(for: "protein", value: protein))
                                                    .font(.custom("Avenir", size: 12))
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                        
                                        // Carbs bar
                                        if let carbs = nutritionValues["carbs"], carbs > 0 {
                                            VStack(alignment: .leading, spacing: 2) {
                                                NutritionBar(
                                                    label: "Carbs",
                                                    value: "\(Int(carbs))g",
                                                    percentage: min(carbs / 100, 1.0),
                                                    color: Color(hex: "#2196F3")
                                                )
                                                
                                                Text(getNutritionDescription(for: "carbs", value: carbs))
                                                    .font(.custom("Avenir", size: 12))
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                        
                                        // Fat bar
                                        if let fat = nutritionValues["fat"], fat > 0 {
                                            VStack(alignment: .leading, spacing: 2) {
                                                NutritionBar(
                                                    label: "Fat",
                                                    value: "\(Int(fat))g",
                                                    percentage: min(fat / 40, 1.0),
                                                    color: Color(hex: "#F44336")
                                                )
                                                
                                                Text(getNutritionDescription(for: "fat", value: fat))
                                                    .font(.custom("Avenir", size: 12))
                                                    .foregroundColor(.gray)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 10)
                                    
                                    Divider()
                                    
                                    // Analysis summary
                                    Text("Analysis Summary")
                                        .font(.custom("Avenir", size: 16))
                                        .fontWeight(.bold)
                                    
                                    Text(analysisSummary)
                                        .font(.custom("Avenir", size: 14))
                                        .lineSpacing(5)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(radius: 10)
                    .padding(.horizontal, 20)
                }
            }
        }
        
        struct NutritionBar: View {
            let label: String
            let value: String
            let percentage: Double
            let color: Color
            
            var body: some View {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(label)
                            .font(.custom("Avenir", size: 14))
                            .foregroundColor(.black)
                        
                        Spacer()
                        
                        Text(value)
                            .font(.custom("Avenir", size: 14))
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                    }
                    
                    ZStack(alignment: .leading) {
                        // Background bar
                        Rectangle()
                            .frame(height: 8)
                            .foregroundColor(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                        
                        // Value bar
                        Rectangle()
                            .frame(width: max(CGFloat(percentage) * UIScreen.main.bounds.width * 0.7, 10), height: 8)
                            .foregroundColor(color)
                            .cornerRadius(4)
                    }
                }
            }
        }
