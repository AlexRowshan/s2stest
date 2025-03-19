//
//  AccountView.swift
//  s2s
//
//  Created by Cory DeWitt on 3/14/25.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    @StateObject private var viewModel: UserProfileViewModel
    
    @State private var isEditingName = false
    @State private var isEditingPhone = false
    @State private var isSelectingEmoji = false
    @State private var tempName = ""
    @State private var tempPhone = ""
    
    // Available emojis for selection
    private let emojiOptions = ["👨‍🍳", "👩‍🍳", "🧑‍🍳", "🍲", "🍳", "🥗", "🥘", "🍔", "🍕", "🍰", "🧁", "🍎", "🥑", "🥦", "🍄"]
    
    init(appState: AppState, recipeViewModel: RecipeViewModel) {
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(appState: appState, recipeViewModel: recipeViewModel))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color(hex: "#8AC36F"), Color.white]),
                           startPoint: .top,
                           endPoint: .bottom)
            .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile header
                    VStack(spacing: 10) {
                        Text(viewModel.userProfile?.profileEmoji ?? "👨‍🍳")
                            .font(.system(size: 80))
                            .padding()
                            .onTapGesture {
                                isSelectingEmoji = true
                            }
                        
                        if isEditingName {
                            HStack {
                                TextField("Your Name", text: $tempName)
                                    .font(.custom("Avenir", size: 22))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Button(action: {
                                    viewModel.updateName(tempName)
                                    isEditingName = false
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                
                                Button(action: {
                                    isEditingName = false
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal, 40)
                        } else {
                            Text(viewModel.userProfile?.name.isEmpty ?? true ? "Tap to Set Your Name" : viewModel.userProfile?.name ?? "")
                                .font(.custom("Avenir", size: 22))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .onTapGesture {
                                    tempName = viewModel.userProfile?.name ?? ""
                                    isEditingName = true
                                }
                        }
                    }
                    .padding()
                    .background(Color(hex: "#7cd16b").opacity(0.8))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // User information card
                    VStack(alignment: .leading, spacing: 15) {
//                        Text("Account Information")
//                            .font(.custom("Avenir", size: 18))
//                            .fontWeight(.bold)
//                            .padding(.bottom, 5)
//                        
//                        Divider()
                        
                        //                        HStack {
                        ////                            Text("User ID:")
                        ////                                .font(.custom("Avenir", size: 16))
                        ////                                .foregroundColor(.gray)
                        ////                            Spacer()
                        //                            Text(viewModel.userProfile?.userId.prefix(10) ?? "Not signed in")
                        //                                .font(.custom("Avenir", size: 16))
                        //                                .fontWeight(.medium)
                        //                        }
                        
                        if isEditingPhone {
                            //                            HStack {
                            ////                                Text("Phone:")
                            ////                                    .font(.custom("Avenir", size: 16))
                            ////                                    .foregroundColor(.gray)
                            ////
                            ////                                TextField("Optional", text: $tempPhone)
                            ////                                    .font(.custom("Avenir", size: 16))
                            ////                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            ////                                    .keyboardType(.phonePad)
                            ////
                            ////                                Button(action: {
                            ////                                    viewModel.updatePhoneNumber(tempPhone.isEmpty ? nil : tempPhone)
                            ////                                    isEditingPhone = false
                            ////                                }) {
                            ////                                    Image(systemName: "checkmark.circle.fill")
                            ////                                        .foregroundColor(.green)
                            ////                                }
                            ////
                            ////                                Button(action: {
                            ////                                    isEditingPhone = false
                            ////                                }) {
                            ////                                    Image(systemName: "xmark.circle.fill")
                            ////                                        .foregroundColor(.red)
                            ////                                }
                            //                            }
                        } else {
                            //                            HStack {
                            //                                Text("Phone:")
                            //                                    .font(.custom("Avenir", size: 16))
                            //                                    .foregroundColor(.gray)
                            //                                Spacer()
                            //                                Text(viewModel.userProfile?.phoneNumber ?? "Tap to set")
                            //                                    .font(.custom("Avenir", size: 16))
                            //                                    .fontWeight(.medium)
                            //                                    .onTapGesture {
                            //                                        tempPhone = viewModel.userProfile?.phoneNumber ?? ""
                            //                                        isEditingPhone = true
                            //                                    }
                            //                            }
                        }
                        
                        //                        Divider()
                        //
                        //                        Text("App Statistics")
                        //                            .font(.custom("Avenir", size: 18))
                        //                            .fontWeight(.bold)
                        //                            .padding(.vertical, 5)
                        //
                        //                        HStack {
                        //                            Text("Recipes Created:")
                        //                                .font(.custom("Avenir", size: 16))
                        //                                .foregroundColor(.gray)
                        //                            Spacer()
                        //                            Text("\(viewModel.userProfile?.recipeCount ?? recipeViewModel.recipes.count)")
                        //                                .font(.custom("Avenir", size: 16))
                        //                                .fontWeight(.medium)
                        //                        }
                        //                    }
                        //                    .padding()
                        //                    .background(Color.white)
                        //                    .cornerRadius(15)
                        //                    .shadow(radius: 3)
                        //                    .padding(.horizontal)
                        //
                        // Sign out button
                        Button(action: {
                            appState.isSignedIn = false
                            appState.currentUserID = nil
                        }) {
                            Text("Sign Out")
                                .font(.custom("Avenir", size: 16))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                    .padding(.bottom, 30)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(2)
                        .padding(40)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(15)
                }
                
                if isSelectingEmoji {
                    EmojiSelectorView(
                        emojis: emojiOptions,
                        onSelect: { emoji in
                            viewModel.updateProfileEmoji(emoji)
                            isSelectingEmoji = false
                        },
                        onDismiss: {
                            isSelectingEmoji = false
                        }
                    )
                }
            }
            .navigationTitle("Account")
            .alert("Error", isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onAppear {
                viewModel.loadUserProfile()
            }
        }
    }
    
    struct EmojiSelectorView: View {
        let emojis: [String]
        let onSelect: (String) -> Void
        let onDismiss: () -> Void
        
        var body: some View {
            ZStack {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        onDismiss()
                    }
                
                VStack(spacing: 20) {
                    Text("Select Profile Emoji")
                        .font(.custom("Avenir", size: 18))
                        .fontWeight(.bold)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))]) {
                        ForEach(emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 40))
                                .padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .onTapGesture {
                                    onSelect(emoji)
                                }
                        }
                    }
                    .padding()
                    
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.custom("Avenir", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(Color.gray)
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(hex: "#F5F5F5"))
                .cornerRadius(20)
                .shadow(radius: 10)
                .padding(.horizontal, 40)
            }
        }
    }
}
