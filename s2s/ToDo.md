//
//  ToDo.md
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//
# To-Do:

## FIRST PRIORITY 

### PastRecipesView
- allow user to set emoji's for each recipe (recipe given by AI on creation)
- allow user to reorder entries
- Create subview RecipeInsights that integrates Nutritionist's recipe insights for each entry
- add health metric bar for each entry

### Account-Page
- added to MainTabView
- sign-out button
- displays basic info and num recipes
- should have subscription info
- profile emoji + name

### Login (s2sApp.swift)
- UI should match other pages

### UI Redo
- make prettier

## DEPLOYMENT
### Remove AWS API Gateway/Lambda and move to Cloudflare Workers or Firbase Functions

### Monetization
- I think 7 free recipes per week for free tier and have pro tier=$1/week 
- Or could do one time fee for unlimited (have to look into GPT billing, especially for images)

### Hide repo + clean code
- hide source code with .gitignore
- combine cloudkit imeplementation to Model/Services/CloudKitService.swift
 

## Fix 1: 3/5/25
- colored text for input boxes
- edit added ingredients
- should render LoadingPageView when user clicks submit

## Fix 2: 3/11/25
### LoadingPageView
- renders PastRecipeView on completion for chats
- should refresh page when user is navigate while opening specific recipe
### Improved error handling
### Nutritionist View
- recipe insights
- general nutrition info
- generate/add random recipes


