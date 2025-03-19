//
//  ChatView.swift
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//

import SwiftUI

struct ChatView: View {
    @State private var navigateToPastRecipes = false
    @State private var inputText = ""
    @State private var ingredients: [String] = []
    @State private var allergyText = ""
    @State private var editingIngredient: (index: Int, text: String)? = nil
    @State private var showRecipeGeneration = false
    @State private var initialRecipeCount = 0
    @State private var showManualEntryTip = false

    @ObservedObject var recipeViewModel: RecipeViewModel
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(hex: "#8AC36F"), Color.white]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(ingredients.indices, id: \.self) { index in
                                HStack {
                                    Spacer()
                                    
                                    if editingIngredient?.index == index {
                                        TextField("Edit ingredient", text: Binding(
                                            get: { editingIngredient?.text ?? "" },
                                            set: { editingIngredient?.text = $0 }
                                        ))
                                        .padding()
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                        .submitLabel(.done)
                                        .focused($isEditFocused)
                                        .onSubmit {
                                            saveEdit()
                                        }
                                    } else {
                                        Text(ingredients[index])
                                            .padding()
                                            .background(Color(hex: "#7cd16b"))
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                            .onTapGesture {
                                                startEditing(index: index)
                                            }
                                    }
                                    
                                    Button(action: {
                                        removeIngredient(at: index)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .padding(.leading, 8)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                    }
                    
                    VStack(spacing: 16) {
                        HStack {
                            TextField("Enter an ingredient", text: $inputText)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(Color.black)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                                .submitLabel(.done)
                                .onSubmit {
                                    addIngredient()
                                }
                            
                            Button(action: {
                                addIngredient()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundColor(Color(hex: "#7cd16b"))
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: {
                            startRecipeGeneration()
                        }) {
                            Text("Generate Recipe")
                                .font(.custom("Avenir", size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(ingredients.isEmpty ? Color.gray : Color(hex: "#7cd16b"))
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                        }
                        .disabled(ingredients.isEmpty)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                
                if showRecipeGeneration {
                    CustomGenerationView(
                        ingredients: ingredients,
                        allergyText: "",
                        isPresented: $showRecipeGeneration,
                        initialRecipeCount: initialRecipeCount
                    )
                    .environmentObject(recipeViewModel)
                    .environmentObject(appState)
                    .transition(.opacity)
                }
            }
            .navigationTitle("Chat2Spoon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.white)
                    }
                }
            }
            .alert("Error", isPresented: Binding<Bool>(
                get: { recipeViewModel.errorMessage != nil },
                set: {_ in
                    if recipeViewModel.errorMessage != nil {
                        showManualEntryTip = true
                    }
                    recipeViewModel.errorMessage = nil
                }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text((recipeViewModel.errorMessage ?? "") +
                     "\n\nTry entering ingredients manually.")
            }
            .alert("Suggestion", isPresented: $showManualEntryTip) {
                Button("Continue", role: .cancel) { }
            } message: {
                Text("You can continue entering ingredients manually to generate a recipe.")
            }
        }
        .onChange(of: showRecipeGeneration) { isShowing in
            if !isShowing && recipeViewModel.recipes.count > initialRecipeCount {
                // Navigate to the My Recipes tab after recipe generation
                // This change ensures we stay within the tab structure
                DispatchQueue.main.async {
                    // Send a notification that will be caught by MainTabView to switch tabs
                    NotificationCenter.default.post(name: Notification.Name("SwitchToRecipesTab"), object: nil)
                }
            }
        }
    }
    
    @FocusState private var isEditFocused: Bool
    
    // MARK: - Ingredient Management
    private func addIngredient() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ingredients.append(trimmed)
        inputText = ""
    }
    
    private func removeIngredient(at index: Int) {
        ingredients.remove(at: index)
        // If removing the ingredient we're currently editing, cancel the edit
        if editingIngredient?.index == index {
            editingIngredient = nil
        }
    }
    
    private func startEditing(index: Int) {
        editingIngredient = (index, ingredients[index])
        isEditFocused = true
    }
    
    private func saveEdit() {
        guard let editing = editingIngredient else { return }
        let trimmed = editing.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmed.isEmpty {
            ingredients[editing.index] = trimmed
        }
        
        editingIngredient = nil
        isEditFocused = false
    }
    
    private func startRecipeGeneration() {
        initialRecipeCount = recipeViewModel.recipes.count
        withAnimation {
            showRecipeGeneration = true
        }
    }
}
//struct CustomGenerationView: View {
//    let ingredients: [String]
//    let allergyText: String
//    @Binding var isPresented: Bool
//    let initialRecipeCount: Int
//    
//    @EnvironmentObject var recipeViewModel: RecipeViewModel
//    @EnvironmentObject var appState: AppState
//    @State private var navigateToRecipes = false
//    @State private var newRecipeCreated = false
//    
//    var body: some View {
//        ZStack {
//            Color.black.opacity(0.4)
//                .edgesIgnoringSafeArea(.all)
//                .onTapGesture {
//                    // Only allow dismissal if we're not loading
//                    if !recipeViewModel.isLoading {
//                        withAnimation {
//                            isPresented = false
//                        }
//                    }
//                }
//            
//            if recipeViewModel.isLoading {
//                LoadingPageView()
//            } else if newRecipeCreated {
//                NavigationStack {
//                    PastRecipesView()
//                        .environmentObject(recipeViewModel)
//                        .environmentObject(appState)
//                }
//                .transition(.move(edge: .trailing))
//            }
//        }
//        .onAppear {
//            // Start recipe generation when this view appears
//            recipeViewModel.generateRecipesFromChat(ingredients: ingredients, allergyText: allergyText)
//        }
//        .onChange(of: recipeViewModel.recipes.count) { newCount in
//            if !recipeViewModel.isLoading && newCount > initialRecipeCount {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                    withAnimation {
//                        newRecipeCreated = true
//                    }
//                }
//            }
//        }
//    }
//}
struct CustomGenerationView: View {
    let ingredients: [String]
    let allergyText: String
    @Binding var isPresented: Bool
    let initialRecipeCount: Int
    
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    @EnvironmentObject var appState: AppState
    @State private var navigateToPastRecipes = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    if !recipeViewModel.isLoading {
                        withAnimation {
                            isPresented = false
                        }
                    }
                }
            
            if recipeViewModel.isLoading {
                LoadingPageView()
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            recipeViewModel.generateRecipesFromChat(ingredients: ingredients, allergyText: allergyText)
        }
        .onChange(of: recipeViewModel.errorMessage) { errorMessage in
            if errorMessage != nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
        .onChange(of: recipeViewModel.recipes.count) { newCount in
            if !recipeViewModel.isLoading && newCount > initialRecipeCount {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isPresented = false // Simply dismiss this view without navigation
                    }
                }
            }
        }
    }
}
