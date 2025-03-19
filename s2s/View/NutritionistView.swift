import SwiftUI

struct NutritionistView: View {
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    @EnvironmentObject var appState: AppState
    @State private var showPastRecipes = false
    @State private var selectedRecipe: RecipeModel? = nil
    @State private var showAnalysis = false
    @State private var userQuestion = ""
    @State private var chatMessages: [NutritionChatMessage] = []
    @State private var scrollToBottom = false
    
    @StateObject private var viewModel = NutritionistViewModel(recipeViewModel: RecipeViewModel(appState: AppState()))
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#8AC36F"), Color.white]),
                           startPoint: .top,
                           endPoint: .bottom)
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🥕")
                        .font(.system(size: 30))
                    Text("Nutritionist Chat")
                        .font(.custom("Scripto", size: 26))
                        .foregroundColor(.white)
                }
                .padding(.top, 15)
                .padding(.bottom, 5)
                
                // Chat messages area
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Welcome message
                            if chatMessages.isEmpty {
                                NutritionistMessageBubble(message: "Hello! I'm your nutrition assistant. I can answer your nutrition questions. What would you like to know?")
                                    .padding(.top, 10)
                            }
                            
                            // All chat messages
                            ForEach(chatMessages) { message in
                                if message.isFromUser {
                                    UserMessageBubble(message: message.text)
                                } else if message.isRecipe, let recipe = message.recipe {
                                    ImprovedRecipeBubble(recipe: recipe) {
                                        viewModel.saveRecipeToUserCollection(recipe)
                                        addMessage(NutritionChatMessage(
                                            text: "I've added '\(recipe.name)' to your recipes!",
                                            isFromUser: false,
                                            isRecipe: false
                                        ))
                                    }
                                } else {
                                    NutritionistMessageBubble(message: message.text)
                                }
                            }
                            
                            // Anchor for scrolling to bottom
                            Color.clear
                                .frame(height: 1)
                                .id("bottomAnchor")
                        }
                        .padding(.horizontal)
                    }
                    .onChange(of: chatMessages.count) { _ in
                        withAnimation {
                            scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: scrollToBottom) { _ in
                        withAnimation {
                            scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                        }
                    }
                }
                .padding(.top, 5)
                .background(Color.white.opacity(0.9))
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: {
                        let userMessage = "Generate a healthy recipe" + (viewModel.userInput.isEmpty ? "" : " for \(viewModel.userInput)")
                        addMessage(NutritionChatMessage(text: userMessage, isFromUser: true))
                        
                        // Clear input after use
                        let preferences = viewModel.userInput
                        viewModel.userInput = ""
                        
                        // Generate recipe
                        viewModel.generateHealthyRecipe(dietaryPreferences: preferences)
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 20))
                            Text("Random Recipes")
                                .font(.custom("Avenir", size: 10))
                        }
                        .foregroundColor(.white)
                        .frame(width: 70, height: 60)
                        .background(Color(hex: "#7cd16b"))
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                    
                    // Input bar
                    HStack {
                        TextField("Ask about nutrition...", text: $viewModel.userInput)
                            .padding(10)
                            .background(Color.white)
                            .cornerRadius(20)
                            .shadow(radius: 2)
                        
                        Button(action: {
                            sendUserQuestion()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(Color(hex: "#7cd16b"))
                        }
                        .disabled(viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.9))
                    .cornerRadius(25)
                    .shadow(radius: 2)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.9))
            }
            
            // Loading overlay (only for recipe generation)
            if viewModel.isLoading && viewModel.showRecipeGeneration {
                LoadingPageView()
                    .edgesIgnoringSafeArea(.all)
            } else if viewModel.isLoading {
                // Simple loading indicator for questions
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#7cd16b")))
                            .scaleEffect(2)
                            .padding(40)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(15)
                        Spacer()
                    }
                    Spacer()
                }
            }
            
        }
        .onReceive(viewModel.$healthyRecipes) { recipes in
            if !recipes.isEmpty && viewModel.generationCompleted {
                // Add recipes to the chat
                for recipe in recipes {
                    addMessage(NutritionChatMessage(
                        text: "",
                        isFromUser: false,
                        isRecipe: true,
                        recipe: recipe
                    ))
                }
                viewModel.healthyRecipes = [] // Clear after adding to chat
            }
        }
        .onReceive(viewModel.$nutritionAnalysis) { analysis in
            if !analysis.isEmpty {
                addMessage(NutritionChatMessage(
                    text: "Here's my analysis:\n\n\(analysis)",
                    isFromUser: false
                ))
            }
        }
        .onReceive(viewModel.$nutritionistResponse) { response in
            if !response.isEmpty {
                // Remove "Typing..." message if it exists
                if let lastIndex = chatMessages.lastIndex(where: { $0.text == "Typing..." && !$0.isFromUser }) {
                    chatMessages.remove(at: lastIndex)
                }
                
                addMessage(NutritionChatMessage(
                    text: response,
                    isFromUser: false
                ))
                viewModel.nutritionistResponse = ""
            }
        }
        .alert("Error", isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            viewModel.updateRecipeViewModel(recipeViewModel)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scrollToBottom.toggle()
            }
        }
    }
    
    private func addMessage(_ message: NutritionChatMessage) {
        chatMessages.append(message)
        
        // Ensure UI updates
        DispatchQueue.main.async {
            self.scrollToBottom.toggle()
        }
    }
    
    private func sendUserQuestion() {
        guard !viewModel.userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userInputText = viewModel.userInput
        
        // Add user's question to chat
        addMessage(NutritionChatMessage(text: userInputText, isFromUser: true))
        viewModel.userInput = ""
        
        // Add typing indicator
        addMessage(NutritionChatMessage(
            text: "Typing...",
            isFromUser: false
        ))
        
        // Send to nutritionist for answer
        viewModel.answerNutritionQuestion(userInputText)
    }
}

// Nutrition Chat Message Model
struct NutritionChatMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let isRecipe: Bool
    let recipe: RecipeModel?
    let timestamp = Date()
    
    init(text: String, isFromUser: Bool, isRecipe: Bool = false, recipe: RecipeModel? = nil) {
        self.text = text
        self.isFromUser = isFromUser
        self.isRecipe = isRecipe
        self.recipe = recipe
    }
    
    static func == (lhs: NutritionChatMessage, rhs: NutritionChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.text == rhs.text &&
               lhs.isFromUser == rhs.isFromUser &&
               lhs.isRecipe == rhs.isRecipe &&
               lhs.recipe?.id == rhs.recipe?.id
    }
}

// Chat UI Components
struct UserMessageBubble: View {
    let message: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(message)
                .padding(12)
                .background(Color(hex: "#DCF8C6"))
                .foregroundColor(.black)
                .cornerRadius(18)
                .padding(.leading, 60)
        }
    }
}

struct NutritionistMessageBubble: View {
    let message: String
    
    var body: some View {
        HStack {
            Text(message)
                .padding(12)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(18)
                .padding(.trailing, 60)
                .shadow(color: Color.black.opacity(0.1), radius: 1)
            Spacer()
        }
    }
}

struct ImprovedRecipeBubble: View {
    let recipe: RecipeModel
    let onSave: () -> Void
    @State private var isExpanded = false
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recipe.name)
                                .font(.custom("Avenir", size: 18))
                                .fontWeight(.bold)
                            Text("Time: \(recipe.duration) • Difficulty: \(recipe.difficulty)")
                                .font(.custom("Avenir", size: 14))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(Color(hex: "#7cd16b"))
                            .font(.system(size: 16))
                            .padding(8)
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    if isExpanded {
                        Divider()
                            .padding(.vertical, 5)
                        
                        Group {
                            Text("Ingredients:")
                                .font(.custom("Avenir", size: 16))
                                .fontWeight(.semibold)
                            if recipe.ingredients.isEmpty {
                                Text("No ingredients listed.")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(recipe.ingredients, id: \.self) { ingredient in
                                    Text("• \(ingredient)")
                                        .font(.custom("Avenir", size: 14))
                                        .padding(.vertical, 1)
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 5)
                        
                        Group {
                            Text("Instructions:")
                                .font(.custom("Avenir", size: 16))
                                .fontWeight(.semibold)
                            if recipe.instructions.isEmpty {
                                Text("No instructions provided.")
                                    .font(.custom("Avenir", size: 14))
                                    .foregroundColor(.gray)
                            } else {
                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                                    Text("\(index + 1). \(step)")
                                        .font(.custom("Avenir", size: 14))
                                        .padding(.vertical, 1)
                                }
                            }
                        }
                        
                        Button(action: onSave) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Save This Recipe")
                            }
                            .font(.custom("Avenir", size: 16))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(hex: "#7cd16b"))
                            .cornerRadius(15)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(15)
                .background(Color.white)
                .cornerRadius(18)
                .shadow(color: Color.black.opacity(0.1), radius: 2)
            }
            Spacer()
        }
        .padding(.trailing, 40)
    }
}
