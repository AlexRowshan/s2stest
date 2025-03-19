//
//  OpenAIModels.swift
//  s2s
//
//  Created by Cory DeWitt on 2/13/25.
//

import Foundation

struct OpenAIChatResponse: Decodable {
    let id: String
    let choices: [OpenAIChatChoice]
}

struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatMessage
}

struct OpenAIChatMessage: Decodable {
    let role: String
    let content: String
}
