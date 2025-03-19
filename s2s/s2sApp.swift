import SwiftUI
import AuthenticationServices

class AppState: ObservableObject {
    @Published var isSignedIn: Bool = false
    @Published var currentUserID: String? {
        didSet {
            UserDefaults.standard.set(currentUserID, forKey: "currentUserID")
        }
    }
    init() {
        self.currentUserID = UserDefaults.standard.string(forKey: "currentUserID")
        print("Current User ID: \(currentUserID ?? "(none)")")
        self.isSignedIn = currentUserID != nil
    }
}

@main
struct s2s: App {
    @StateObject var appState: AppState
    @StateObject var recipeViewModel: RecipeViewModel
    @StateObject var capturedImageViewModel: CapturedImageViewModel

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        
        let recipeVM = RecipeViewModel(appState: state)
        _recipeViewModel = StateObject(wrappedValue: recipeVM)
        
        _capturedImageViewModel = StateObject(wrappedValue: CapturedImageViewModel(recipeViewModel: recipeVM))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentRootView()
                    .environmentObject(appState)
                    .environmentObject(recipeViewModel)
                    .environmentObject(capturedImageViewModel)
            }
        }
    }
}

struct ContentRootView: View {
    @EnvironmentObject var appState: AppState
    
    
    var body: some View {
        Group {
            if appState.isSignedIn {
                MainTabView()
                    .environmentObject(appState)
            } else {
                LoginView()
            }
        }
    }
}


struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to Snap2Spoon")
                .font(.custom("Scripto-2OR2v", size: 32))
                .foregroundColor(Color(hex: "#7FBD61"))
                .padding(.top, 40)
                .fontWeight(.bold)
            
            
            
            Text("Let AI help you be healthier")
                .font(.custom("Scripto-2OR2v", size: 24))
                .foregroundColor(Color(hex: "#7FBD61"))
                .padding(.top, 40)
                .fontWeight(.bold)

            Spacer()
                        
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                            let userIdentifier = appleIDCredential.user
                            appState.currentUserID = userIdentifier
                            appState.isSignedIn = true
                            recipeViewModel.loadRecipes()
                        }
                    case .failure(let error):
                        print("Authorization failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(width: 280, height: 45)
            .padding()
            
            Spacer()
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var recipeViewModel: RecipeViewModel
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Homepage()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(0)
                
            PastRecipesView()
                .tabItem {
                    Label("My Recipes", systemImage: "book")
                }
                .badge(recipeViewModel.recipes.count)
                .tag(1)
            
            NutritionistView()
                .environmentObject(recipeViewModel)
                .environmentObject(appState)
                .tabItem {
                    Label("Nutritionist", systemImage: "carrot")
                }
                .tag(2)
            
            AccountView(appState: appState, recipeViewModel: recipeViewModel)
                .tabItem {
                    Label("Account", systemImage: "person")
                }
                .tag(3)
        }
        .environmentObject(appState)
        .environmentObject(recipeViewModel)
        .onAppear {
            recipeViewModel.loadRecipes()
            
            // Set up notification observer to switch tabs programmatically
            NotificationCenter.default.addObserver(forName: Notification.Name("SwitchToRecipesTab"),
                                                 object: nil,
                                                 queue: .main) { _ in
                withAnimation {
                    selectedTab = 1 // Index of My Recipes tab
                }
            }
            
            // Set the tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(hexString: "#363636")
            
            // Set the selected and unselected colors
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(hexString: "#7cd16b")
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(hexString: "#7cd16b")]
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}
// Helper extension to create UIColor from hex string
extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
