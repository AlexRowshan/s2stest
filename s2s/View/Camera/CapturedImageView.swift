import SwiftUI

struct CapturedImageView: View {
    @StateObject private var viewModel: CapturedImageViewModel
    @State private var showCamera = false
    @State private var navigateToRecipes = false
    @State private var showErrorTip = false
    
    let image: UIImage?
    
    @Environment(\.dismiss) var dismiss

    init(image: UIImage?, recipeViewModel: RecipeViewModel) {
        self.image = image
        self._viewModel = StateObject(wrappedValue: CapturedImageViewModel(recipeViewModel: recipeViewModel))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    if viewModel.isLoading {
                        LoadingPageView()
                    } else if image == nil {
                        VStack(spacing: 20) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("Take a Photo of Your Receipt")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                            
                            Text("We'll generate recipe suggestions based on your groceries")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: {
                                showCamera = true
                            }) {
                                Text("Open Camera")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(12)
                                    .padding(.horizontal, 40)
                            }
                        }
                    } else {
                        VStack {
                            if let capturedImage = image {
                                Image(uiImage: capturedImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 300)
                                    .cornerRadius(12)
                                    .padding()
                            }
                            
                            Text("Processing receipt...")
                                .font(.headline)
                        }
                    }
                    
                    Spacer()
                }
                
                if navigateToRecipes {
                    NavigationLink(destination: PastRecipesView(), isActive: $navigateToRecipes) {
                        EmptyView()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraView { image in
                    viewModel.processImage(image: image)
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: {_ in 
                    if viewModel.errorMessage != nil {
                        showErrorTip = true
                    }
                    viewModel.errorMessage = nil
                }
            )) {
                Button("Try Again", role: .cancel) {
                    // Reset state to allow user to try again
                }
                
                Button("Enter Manually") {
                    // Navigate to chat view for manual entry
                    dismiss()
                }
            } message: {
                Text((viewModel.errorMessage ?? "") +
                     "\n\nYou can try again or enter ingredients manually.")
            }
            .alert("Suggestion", isPresented: $showErrorTip) {
                Button("OK", role: .cancel) {
                    // Dismiss and go back after showing suggestion
                    dismiss()
                }
            } message: {
                Text("You can enter ingredients manually in the Chat2Spoon section.")
            }
            .navigationTitle("Snap2Spoon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
            .onAppear {
                if let image = image {
                    viewModel.processImage(image: image)
                }
            }
            .onChange(of: viewModel.recipes) { recipes in
                if !recipes.isEmpty {
                    navigateToRecipes = true
                }
            }
        }
    }
}
