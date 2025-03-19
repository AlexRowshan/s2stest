//
//  UserProfileModel.swift
//  s2s
//
//  Created by Cory DeWitt on 3/14/25.
//

import Foundation
import CloudKit

struct UserProfileModel: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var userId: String
    var name: String
    var phoneNumber: String?
    var profileEmoji: String
    var recipeCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, userId, name, phoneNumber, profileEmoji, recipeCount
    }
    
    init(id: String = UUID().uuidString,
         userId: String,
         name: String = "",
         phoneNumber: String? = nil,
         profileEmoji: String = "👨‍🍳",
         recipeCount: Int = 0) {
        self.id = id
        self.userId = userId
        self.name = name
        self.phoneNumber = phoneNumber
        self.profileEmoji = profileEmoji
        self.recipeCount = recipeCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(String.self, forKey: .id)) ?? UUID().uuidString
        userId = try container.decode(String.self, forKey: .userId)
        name = (try? container.decode(String.self, forKey: .name)) ?? ""
        phoneNumber = try? container.decode(String?.self, forKey: .phoneNumber)
        profileEmoji = (try? container.decode(String.self, forKey: .profileEmoji)) ?? "👨‍🍳"
        recipeCount = (try? container.decode(Int.self, forKey: .recipeCount)) ?? 0
    }
    
    init(record: CKRecord) {
        self.id = record.recordID.recordName
        self.userId = record["userId"] as? String ?? ""
        self.name = record["name"] as? String ?? ""
        self.phoneNumber = record["phoneNumber"] as? String
        self.profileEmoji = record["profileEmoji"] as? String ?? "👨‍🍳"
        self.recipeCount = record["recipeCount"] as? Int ?? 0
    }
    
    func toRecord() -> CKRecord {
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: "UserProfile", recordID: recordID)
        record["userId"] = userId
        record["name"] = name
        record["phoneNumber"] = phoneNumber
        record["profileEmoji"] = profileEmoji
        record["recipeCount"] = recipeCount
        
        return record
    }
    
    static func == (lhs: UserProfileModel, rhs: UserProfileModel) -> Bool {
        return lhs.id == rhs.id
    }
}
