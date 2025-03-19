//
//  ChatMessage.swift
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//

import Foundation

struct ChatMessage: Identifiable {
    let id: String
    let content: String
    let dateCreated: Date
    let sender: MessageSender
}

enum MessageSender {
    case me
    case gpt
    
    var role: String {
        switch self {
        case .me:
            return "user"
        case .gpt:
            return "assistant"
        }
    }
}
