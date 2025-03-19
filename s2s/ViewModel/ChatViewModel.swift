//
//  ChatViewModel.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/13/24.
//

import Foundation
import Combine

class ChatViewModel: ObservableObject {
    @Published var chatMessages: [ChatMessage] = []
    @Published var inputText: String = ""
    
    private let openAIService = OpenAIService()
    private var cancellables = Set<AnyCancellable>()
    
    func sendMessage() {
            guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            let userMessage = ChatMessage(
                id: UUID().uuidString,
                content: inputText,
                dateCreated: Date(),
                sender: .me
            )
            chatMessages.append(userMessage)
            
            openAIService.sendMessage(messages: chatMessages)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .failure(let error):
                        print("Chat API Error: \(error.localizedDescription)")
                    case .finished:
                        break
                    }
                } receiveValue: { [weak self] response in
                    guard let self = self,
                          let gptReply = response.choices.first?.message.content else { return }
                    let gptMessage = ChatMessage(
                        id: UUID().uuidString,
                        content: gptReply,
                        dateCreated: Date(),
                        sender: .gpt
                    )
                    self.chatMessages.append(gptMessage)
                }
                .store(in: &cancellables)
            
            inputText = ""
        }

}
