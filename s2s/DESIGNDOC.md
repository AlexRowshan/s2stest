//
//  DESIGNDOC.md
//  s2s
//
//  Created by Cory DeWitt on 3/14/25.
//

# Snap2Spoon Design Document

## Executive Summary
Snap2Spoon is an iOS application that leverages AI to generate personalized recipes based on two primary inputs:

* Photos of grocery receipts (Snap)
* Manual ingredient input via chat (Chat)

The app aims to reduce food waste, inspire creativity in cooking, and simplify meal planning by suggesting recipes that utilize ingredients the user already has on hand.

## App Architecture

### Core Components

#### Authentication System
* Sign in with Apple integration
* User persistence via UserDefaults
* CloudKit integration for secure data storage

#### Recipe Generation Engine
* OpenAI API integration (GPT models)
* Image processing for receipt scanning
* Natural language processing for ingredient extraction
* JSON parsing and validation

#### Recipe Management System
* Local storage via UserDefaults
* Cloud synchronization via CloudKit
* CRUD operations for user recipes
* Nutritional analysis for recipes

#### Nutritionist System
* AI-powered nutritional advice
* Healthy recipe generation
* Recipe analysis with health metrics

#### User Profile Management
* CloudKit-based user profiles
* Customizable user information
* Recipe statistics tracking

#### UI Framework
* SwiftUI-based interface
* Tab-based navigation with consistent styling
* Custom animations and transitions
* Responsive design elements
* Aesthetically pleasing color schemes

### Data Flow

```
User Input (Image/Text) → OpenAI API → JSON Response → Recipe Model → 
UI Display → CloudKit Storage → User Devices
```

## User Interface

### Tab-Based Navigation

The app employs a tab-based navigation system with four primary sections:

#### Home Tab
* Welcome screen
* Quick access to recipe generation methods
* Featured recipes or tips

#### My Recipes Tab
* Chronologically sorted list of saved recipes (newest first)
* Expandable recipe cards with details
* Nutritional analysis with health metrics bar
* Delete functionality via context menu
* Refresh button to sync with CloudKit

#### Nutritionist Tab
* Interactive ingredient input interface
* Editable ingredient bubbles
* Allergy specification field
* Recipe generation trigger
* Viewable recipe content when expanded

#### Account Tab
* User profile information display
* Editable name and contact information
* Profile emoji selection

### Key Screens

#### Login View
* Sign in with Apple button
* Branded welcome text with custom font
* Clean, minimalist design

#### Chat View
* Gradient background (green to white)
* Interactive ingredient entry with add/edit/delete functionality
* Allergies input field
* Generate Recipe button with conditional styling

#### Loading View
* Circular animation with rotating food icons
* Central receipt icon
* Progress indicator
* Branded header

#### Recipe View
* Expandable recipe cards with improved styling
* Alternate color scheme for better aesthetics
* Detailed view with:
  * Duration and difficulty indicators
  * Ingredient list with bullet points
  * Step-by-step instructions
  * Nutritional breakdown with health metrics bar
  * Delete functionality

#### Account View
* User information display
* Editable profile fields
* Recipe statistics
* Profile emoji selector
* Settings options

## Technical Implementation

### State Management
The app uses the following state objects:

* AppState: Manages authentication state and user identity
* RecipeViewModel: Handles recipe data operations and API communication
* CapturedImageViewModel: Manages the camera and image processing workflows
* NutritionistViewModel: Handles nutritional analysis and advice
* UserProfileViewModel: Manages user profile data

### API Integration
The app communicates with OpenAI's API using:

* GPT-3.5 Turbo for chat-based recipe generation
* GPT-4o for image-based recipe generation (receipt scanning)
* Custom prompts designed to generate structured JSON responses

### Data Models

#### RecipeModel
```swift
struct RecipeModel: Identifiable, Codable, Equatable {
    var id: String
    var userId: String
    var name: String
    var duration: String
    var difficulty: String
    var ingredients: [String]
    var instructions: [String]
    var nutritionalInfo: [String: String]?
    var healthBenefits: [String]?
}
```

#### UserProfileModel
```swift
struct UserProfileModel: Identifiable, Codable {
    var id: String
    var userId: String
    var name: String
    var phoneNumber: String?
    var profileEmoji: String
    var recipeCount: Int
}
```

#### ChatMessage
```swift
struct ChatMessage {
    var id: String
    var content: String
    var dateCreated: Date
    var sender: MessageSender
}
```

### CloudKit Integration
* Public database usage for recipe and user profile storage
* Record types: "Recipe" and "UserProfile"
* Queries filtered by userId
* Automatic synchronization on app launch and after recipe creation

## User Flows

### Receipt Scanning Flow
1. User navigates to home screen
2. User captures photo of receipt
3. Loading animation displays
4. Receipt is processed by OpenAI API
5. Recipe is generated and saved
6. User is navigated to recipe detail view

### Chat Input Flow
1. User navigates to chat tab
2. User inputs ingredients manually
3. User specifies any allergies
4. User taps "Generate Recipe"
5. Loading animation displays
6. Ingredients are processed by OpenAI API
7. Recipe is generated and saved
8. User is navigated to recipe detail view

### Recipe Management Flow
1. User navigates to My Recipes tab
2. User views list of recipes (newest first)
3. User taps recipe to expand details
4. User can view nutritional breakdown and health metrics
5. User can delete recipe via context menu
6. User can refresh via sync button

### Account Management Flow
1. User navigates to Account tab
2. User views profile information
3. User can edit name and contact details
4. User can select a profile emoji
5. User can view recipe statistics

## Visual Design Elements

### Color Palette
* Primary Green: #7cd16b / #80D05B (brand color)
* Secondary Green: #8AC36F (gradient start)
* Background White: #FCFCFC
* Tab Background: #363636 (solid dark color)
* Recipe Card Colors: #F1F8E9, #E8F5E9, #DCEDC8 (alternating)
* Text: White (on dark backgrounds), Dark Gray (on light backgrounds)

### Typography
* Brand Font: "Scripto" (custom font for headers)
* Primary Font: "Avenir" (for body text and UI elements)
* Font Sizes: 32px (headers), 18px (subheaders), 14-16px (body text)

### UI Components
* Rounded corners (12px radius)
* Subtle shadows (opacity 0.2-0.8)
* Gradient backgrounds
* Custom animations for loading and transitions
* Health metric visualization bars
* Alternating color scheme for recipe cards

## New Features Implementation

### Past Recipes View Enhancements
* Chronological ordering (newest first)
* Improved recipe card design with alternating colors
* Added nutritional analysis with health metrics bar
* Moved recipe analysis functionality from Nutritionist tab

### Nutritionist View Improvements
* Removed analysis button
* Fixed recipe content visibility issue
* Enhanced recipe display

### Account Tab Addition
* New tab for user profile management
* CloudKit integration for user data
* Profile customization options
* Recipe statistics display

### Main Tab View Styling
* Solid background color for better navigation visibility
* Consistent tab styling across the app
* Improved visual hierarchy

## Future Enhancements

### Ingredient Recognition Improvements
* Enhanced OCR for better receipt scanning
* Product name to ingredient mapping

### Recipe Customization
* Ability to edit generated recipes
* Serving size adjustments
* Dietary preference filters

### Social Features
* Recipe sharing
* Community recipe discovery
* Ratings and reviews

### Shopping List Integration
* Missing ingredient identification
* Automated shopping list generation
* Integration with grocery delivery services

### Meal Planning
* Weekly meal planning calendar
* Nutrition information
* Dietary goal tracking

## Technical Considerations

### Performance Optimization
* Efficient CloudKit operations
* Image compression for API requests
* Pagination for recipe lists
* Background processing for API calls

### Offline Support
* Local caching of recipes
* Queued operations for offline recipe generation
* Sync status indicators

### Security
* Secure handling of user data
* Apple authentication integration
* API key protection

## Development Roadmap

### Phase 1: Core Functionality (Complete)
* Authentication
* Recipe generation (both methods)
* Basic recipe management
* CloudKit integration

### Phase 2: UI and UX Enhancements (Current)
* Improved recipe list view
* Nutritionist chat fixes
* Added Account tab
* Enhanced visual design
* Health metrics visualization
* Recipe analysis integration

### Phase 3: Advanced Features (Planned)
* Meal planning
* Shopping list integration
* Social sharing
* Dietary analysis
* Additional user customization

## Conclusion

Snap2Spoon continues to evolve as an innovative approach to recipe discovery by leveraging AI to transform both physical receipts and manual ingredient lists into personalized recipe suggestions. The updated design enhances the user experience with improved aesthetics, better organization, and new features like nutritional analysis and user profiles.

The implementation provides a solid foundation for future enhancements, with a focus on user experience, performance, and reliability. The modular architecture allows for scalable development and feature expansion as the app evolves.
