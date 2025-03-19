//
//  UserProfileViewModel.swift
//  s2s
//
//  Created by Cory DeWitt on 3/14/25.
//

import Foundation
import Combine
import CloudKit

class UserProfileViewModel: ObservableObject {
    @Published var userProfile: UserProfileModel?
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private let appState: AppState
    private let recipeViewModel: RecipeViewModel
    private var cancellables = Set<AnyCancellable>()
    private let cloudDatabase = CKContainer.default().publicCloudDatabase
    
    init(appState: AppState, recipeViewModel: RecipeViewModel) {
        self.appState = appState
        self.recipeViewModel = recipeViewModel
        
        loadUserProfile()
        
        // Update recipe count whenever recipes change
        recipeViewModel.$recipes
            .sink { [weak self] recipes in
                self?.updateRecipeCount(recipes.count)
            }
            .store(in: &cancellables)
    }
    
    func loadUserProfile() {
        guard let userId = appState.currentUserID else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Try to load from local storage first
        if let data = UserDefaults.standard.data(forKey: "userProfile_\(userId)") {
            do {
                let decodedProfile = try JSONDecoder().decode(UserProfileModel.self, from: data)
                if decodedProfile.userId == userId {
                    self.userProfile = decodedProfile
                }
            } catch {
                print("Error decoding user profile: \(error)")
            }
        }
        
        // Then check CloudKit for the latest version
        let predicate = NSPredicate(format: "userId == %@", userId)
        let query = CKQuery(recordType: "UserProfile", predicate: predicate)
        
        cloudDatabase.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    if (error as NSError).code != CKError.unknownItem.rawValue {
                        self?.errorMessage = "CloudKit Error: \(error.localizedDescription)"
                    } else {
                        // No record found - this is fine for new users
                        self?.createNewUserProfile()
                    }
                    return
                }
                
                if let records = records, let record = records.first {
                    // User profile exists in CloudKit
                    let cloudProfile = UserProfileModel(record: record)
                    self?.userProfile = cloudProfile
                    self?.saveUserProfileLocally(cloudProfile)
                } else {
                    // No profile found in CloudKit - create a new one
                    self?.createNewUserProfile()
                }
            }
        }
    }
    
    private func createNewUserProfile() {
        guard let userId = appState.currentUserID, userProfile == nil else { return }
        
        let newProfile = UserProfileModel(
            userId: userId,
            name: "",
            phoneNumber: nil,
            profileEmoji: "👨‍🍳",
            recipeCount: recipeViewModel.recipes.count
        )
        
        self.userProfile = newProfile
        self.saveUserProfile(newProfile)
    }
    
    private func saveUserProfileLocally(_ profile: UserProfileModel) {
        guard let userId = appState.currentUserID else { return }
        
        do {
            let encoded = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(encoded, forKey: "userProfile_\(userId)")
        } catch {
            print("Error saving user profile locally: \(error)")
        }
    }
    
    func saveUserProfile(_ profile: UserProfileModel? = nil) {
        let profileToSave = profile ?? userProfile
        guard let profile = profileToSave else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Save locally first
        saveUserProfileLocally(profile)
        
        // Then try to save to CloudKit
        let record = profile.toRecord()
        
        // Check if record with this ID exists
        let recordID = CKRecord.ID(recordName: profile.id)
        
        cloudDatabase.fetch(withRecordID: recordID) { [weak self] (existingRecord, error) in
            if let existingRecord = existingRecord {
                // Update existing record
                existingRecord["name"] = profile.name
                existingRecord["phoneNumber"] = profile.phoneNumber
                existingRecord["profileEmoji"] = profile.profileEmoji
                existingRecord["recipeCount"] = profile.recipeCount
                
                self?.cloudDatabase.save(existingRecord) { (savedRecord, error) in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        
                        if let error = error {
                            self?.errorMessage = "CloudKit Error: \(error.localizedDescription)"
                        } else if let savedRecord = savedRecord {
                            let updatedProfile = UserProfileModel(record: savedRecord)
                            self?.userProfile = updatedProfile
                        }
                    }
                }
            } else {
                // Create new record
                self?.cloudDatabase.save(record) { (savedRecord, error) in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        
                        if let error = error {
                            if error.localizedDescription.contains("already exists") {
                                print("Conflict in record creation, attempting update instead")
                                self?.updateUserProfile(profile)
                            } else {
                                self?.errorMessage = "CloudKit Error: \(error.localizedDescription)"
                            }
                        } else if let savedRecord = savedRecord {
                            let savedProfile = UserProfileModel(record: savedRecord)
                            self?.userProfile = savedProfile
                        }
                    }
                }
            }
        }
    }
    
    private func updateUserProfile(_ profile: UserProfileModel) {
        let recordID = CKRecord.ID(recordName: profile.id)
        
        cloudDatabase.fetch(withRecordID: recordID) { [weak self] (record, error) in
            if let error = error {
                DispatchQueue.main.async {
                    if (error as NSError).code == CKError.unknownItem.rawValue {
                        // Record doesn't exist, create a new one
                        let newRecord = profile.toRecord()
                        self?.cloudDatabase.save(newRecord) { (savedRecord, saveError) in
                            if let saveError = saveError {
                                self?.errorMessage = "CloudKit Error: \(saveError.localizedDescription)"
                            } else if let savedRecord = savedRecord {
                                let savedProfile = UserProfileModel(record: savedRecord)
                                self?.userProfile = savedProfile
                                self?.saveUserProfileLocally(savedProfile)
                            }
                        }
                    } else {
                        self?.errorMessage = "CloudKit Error: \(error.localizedDescription)"
                    }
                }
                return
            }
            
            guard let record = record else {
                DispatchQueue.main.async {
                    self?.errorMessage = "CloudKit Error: Record not found"
                }
                return
            }
            
            // Update the record with the new values
            record["name"] = profile.name
            record["phoneNumber"] = profile.phoneNumber
            record["profileEmoji"] = profile.profileEmoji
            record["recipeCount"] = profile.recipeCount
            
            // Save the updated record
            self?.cloudDatabase.save(record) { (savedRecord, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = "CloudKit Error: \(error.localizedDescription)"
                    } else if let savedRecord = savedRecord {
                        let updatedProfile = UserProfileModel(record: savedRecord)
                        self?.userProfile = updatedProfile
                        self?.saveUserProfileLocally(updatedProfile)
                    }
                }
            }
        }
    }
    
    func updateName(_ name: String) {
        guard var profile = userProfile else { return }
        profile.name = name
        userProfile = profile
        saveUserProfile(profile)
    }
    
    func updatePhoneNumber(_ phoneNumber: String?) {
        guard var profile = userProfile else { return }
        profile.phoneNumber = phoneNumber
        userProfile = profile
        saveUserProfile(profile)
    }
    
    func updateProfileEmoji(_ emoji: String) {
        guard var profile = userProfile else { return }
        profile.profileEmoji = emoji
        userProfile = profile
        saveUserProfile(profile)
    }
    
    private func updateRecipeCount(_ count: Int) {
        guard var profile = userProfile, profile.recipeCount != count else { return }
        profile.recipeCount = count
        userProfile = profile
        saveUserProfile(profile)
    }
}
