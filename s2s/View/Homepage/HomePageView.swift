//
//  HomePage.swift
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//

import AVFoundation
import SwiftUI

struct Homepage: View {
    @StateObject private var homepageViewModel = HomepageViewModel()
    @EnvironmentObject var recipeViewModel : RecipeViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(gradient: Gradient(colors: [Color(hex: "#8AC36F"), Color.white]),
                               startPoint: .top,
                               endPoint: .bottom)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Spacer()
                        
                        Rectangle()
                            .fill(Color(hex: "#7FBD61").opacity(0.5))
                            .frame(height: 8)
                            .offset(y: 52)
                            .frame(maxWidth: 280)
                        
                        ZStack(alignment: .bottom) {
                            Text("Snap2Spoon")
                                .font(.custom("Scripto-2OR2v", size: 47))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.bottom, 5)
                        }
                        Text("Turn your receipts to recipes!")
                            .font(.custom("Avenir Next", size: 18))
                            .foregroundColor(.white)
                            .italic()
                    }
                    
                    Spacer().frame(height: 30)
                    
                    ZStack {
                        Image("receipt")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 590, height: 400)
                            .rotationEffect(.degrees(7))
                            .offset(x: 25)
                        
                        Image("shopping_cart")
                            .resizable()
                            .frame(width: 180, height: 180)
                            .offset(x: 0, y: -40)
                            .rotationEffect(.degrees(5))
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer().frame(height: 15)
                    
                    VStack(spacing: 20) {
                        Button(action: {
                            homepageViewModel.showCamera = true
                        }) {
                            Text("Snap2Spoon")
                                .font(.custom("Avenir", size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 180, height: 80)
                                .background(Color(hex: "#7cd16b"))
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                        }
                        
                        
                        NavigationLink(destination: ChatView(recipeViewModel: recipeViewModel, appState: appState)) {
                            Text("Chat2Spoon")
                                .font(.custom("Avenir", size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 180, height: 80)
                                .background(Color(hex: "#7cd16b"))
                                .cornerRadius(15)
                                .shadow(color: .black.opacity(0.8), radius: 5, x: 0, y: 2)
                        }
                    }
                    
                    Spacer().frame(height: 70)
                }
                .padding(.horizontal, 20)
                
            }
            .fullScreenCover(isPresented: $homepageViewModel.showCamera) {
                CameraView(onPhotoCaptured: { image in
                    homepageViewModel.handlePhotoCaptured(image)
                })
            }
            .fullScreenCover(isPresented: $homepageViewModel.navigateToImageView) {
                if let image = homepageViewModel.capturedImage {
                    CapturedImageView(image: image, recipeViewModel: recipeViewModel)
                }
            }
            .alert("Camera Error", isPresented: $homepageViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(homepageViewModel.errorMessage)
            }
        }
    }
}


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}
