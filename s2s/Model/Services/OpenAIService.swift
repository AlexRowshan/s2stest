//
//  OpenAIService.swift
//  Snap2Spoon
//
//  Created by Cory DeWitt on 11/13/24.
//
//
import Foundation
import Alamofire
import Combine

class OpenAIService {
    private let chatURL = "https://api.openai.com/v1/chat/completions"
//    private let chatURL = "https://2u1m018lz9.execute-api.us-east-2.amazonaws.com/api/openai-chat"


    func sendMessage(messages: [ChatMessage]) -> AnyPublisher<OpenAIChatResponse, Error> {
        let chatMessages = messages.map { message in
            [
                "role": message.sender == .me ? "user" : "assistant",
                "content": message.content
            ]
        }

        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": chatMessages
        ]

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)",
            "Content-Type": "application/json"
        ]

        return Future { [weak self] promise in
            guard let self = self else { return }
            AF.request(
                self.chatURL,
                method: .post,
                parameters: body,
                encoding: JSONEncoding.default,
                headers: headers
            )
            .validate()
            .responseDecodable(of: OpenAIChatResponse.self) { response in
                if let data = response.data,
                   let jsonString = String(data: data, encoding: .utf8) {
                    print("Response JSON: \(jsonString)")
                }

                switch response.result {
                case .success(let result):
                    promise(.success(result))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func sendImageMessage(base64Image: String) -> AnyPublisher<OpenAIChatResponse, Error> {
        let prompt = """
        The picture provided is of a grocery receipt. You are an assistant whose job is to create recipes.

        Your first task is to read through this receipt and create a list of ingredients strictly from the receipt.

        There are a certain number of ingredients that can be labeled as "Common Household Ingredients", which I have provided below:

        Common Household Ingredients:
        "Pantry Basics:
            - Flour (all-purpose)
            - Sugar (granulated, brown)
            - Salt (table, kosher)
            - Black pepper
            - Baking soda
            - Baking powder
            - Vanilla extract
            - Cooking oils (vegetable, olive)
            - Vinegar (white, apple cider)
        Seasonings/Spices:
            - Garlic powder
            - Onion powder
            - Cinnamon
            - Paprika
            - Red pepper flakes
            - Italian seasoning
            - Bay leaves
            - Dried oregano
            - Dried basil
            - Ground cumin
        Refrigerator Staples:
            - Butter
            - Eggs
            - Milk
            - Mustard
            - Mayonnaise
            - Ketchup
            - Soy sauce
            - Hot sauce
            - Worcestershire sauce
        Basic Produce:
            - Garlic
            - Onions
            - Lemons/Limes (these are borderline - some might not always have them)

        Please create a combined list of all of the items from the receipt and this Common Household Ingredients list. Do not print out this list.

        Now, please generate an array of 1 recipe in JSON format matching the following structure:

        [
          {
            "name": "Recipe Name",
            "duration": "Cooking Time in minutes",
            "difficulty": "Easy/Medium/Hard",
            "ingredients": ["Ingredient 1", "Ingredient 2", "..."],
            "instructions": ["Step 1", "Step 2", "..."]
          },
          ...
        ]

        Ensure that the JSON is strictly valid and can be parsed by a JSON decoder. The response should only contain the JSON array of recipes without any additional text, headers, backticks, or symbols. Do not add any markdown formatting.
        """

        let messages: [[String: Any]] = [
            [
                "role": "user",
                "content": [
                    [
                        "type": "text",
                        "text": prompt
                    ],
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ]
                ]
            ]
        ]

        let parameters: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 300
        ]

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(Constants.openAIAPIKey)",
            "Content-Type": "application/json"
        ]

        return Future { [weak self] promise in
            guard let self = self else { return }
            AF.request(
                self.chatURL,
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers
            )
            .responseData { response in
                print("Request URL: \(self.chatURL)")
                print("Request Headers: \(headers)")
                print("Request Parameters: \(parameters)")

                if let data = response.data,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("Response Data: \(responseString)")

                }

                if let error = response.error {
                    print("Request Error: \(error)")
                }

                switch response.result {
                case .success(let data):
                    do {
                        let decodedResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
                        print("DECODED RESPONE BRUHHHH: \(decodedResponse)")
                        promise(.success(decodedResponse))
                    } catch {
                        print("Decoding Error: \(error)")
                        promise(.failure(error))
                    }
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}


//import Foundation
//import Alamofire
//import Combine
//// Import a Brotli compression library; for example:
// import SwiftBrotli
//import UIKit
//
//class OpenAIService {
//    private let chatURL = "https://2u1m018lz9.execute-api.us-east-2.amazonaws.com/api/openai-chat"
//    
//    func sendTextMessage(_ text: String) -> AnyPublisher<OpenAIChatResponse, Error> {
//        var prompt = """
//                        Please create a combined list of all of the items from the INPUT TEXT and this Common Household Ingredients list. Do not print out this list.
//                There are a certain number of ingredients that can be labeled as "Common Household Ingredients", which I have provided below:
//                Common Household Ingredients:
//                "Pantry Basics:
//                    - Flour (all-purpose)
//                   - Sugar (granulated, brown)
//                    - Salt (table, kosher)
//                    - Black pepper
//                    - Baking soda
//                    - Baking powder
//                    - Vanilla extract
//                    - Cooking oils (vegetable, olive)
//                    - Vinegar (white, apple cider)
//                Seasonings/Spices:
//                    - Garlic powder
//                    - Onion powder
//                    - Cinnamon
//                    - Paprika
//                    - Red pepper flakes
//                    -  Italian seasoning
//                    - Bay leaves
//                    - Dried oregano
//                    - Dried basil
//                    - Ground cumin
//                Refrigerator Staples:
//                    - Butter
//                    - Eggs
//                   - Milk
//                    - Mustard
//                    - Mayonnaise
//                    - Ketchup
//                    - Soy sauce
//                    - Hot sauce
//                    - Worcestershire sauce
//                Basic Produce:
//                    - Garlic
//                    - Onions
//                    - Lemons/Limes (these are borderline - some might not always have them)
//                Now, please generate an array of 1 recipe in JSON format matching the following structure:
//                [
//                  {
//                    "name": "Recipe Name",
//                    "duration": "Cooking Time in minutes",
//                    "difficulty": "Easy/Medium/Hard",
//                    "ingredients": ["Ingredient 1", "Ingredient 2", "..."],
//                    "instructions": ["Step 1", "Step 2", "..."]
//                  },
//                ]
//                Ensure that the JSON is strictly valid and can be parsed by a JSON decoder. The response should only contain the JSON array of recipes without any additional text, headers, backticks, or symbols. Do not add any markdown formatting. HERE ARE THE INPUT INGREDIENTS!!!!!!!! : 
//                
//        """
//        let payload: [String: Any] = [
//            "model": "gpt-4o",
//            "messages": [
//                [
//                    "role": "user",
//                    "content": "\(prompt): *** \(text)"
//                ]
//            ]
//        ]
//        return performPlainRequest(with: payload)
//    }
//    
//    func performPlainRequest(with payload: [String: Any]) -> AnyPublisher<OpenAIChatResponse, Error> {
//        guard let url = URL(string: chatURL) else {
//            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        // Do not set a "Content-Encoding" header so that the lambda treats this as uncompressed.
//        request.setValue("Bearer gxye69", forHTTPHeaderField: "Authorization")
//        do {
//            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
//        } catch {
//            return Fail(error: error).eraseToAnyPublisher()
//        }
//        request.timeoutInterval = 60
//
//        return Future { promise in
//            AF.request(request)
//                .validate()
//                .responseData { response in
//                    print("Plain request response: \(String(describing: response.debugDescription))")
//                    if let data = response.data, let responseString = String(data: data, encoding: .utf8) {
//                        print("Response String: \(responseString)")
//                    }
//                    switch response.result {
//                    case .success(let data):
//                        do {
//                            let decodedResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
//                            promise(.success(decodedResponse))
//                        } catch {
//                            promise(.failure(error))
//                        }
//                    case .failure(let error):
//                        promise(.failure(error))
//                    }
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    
//    
//    func compressDataBrotli(_ data: Data) -> Data? {
//        let encoder = BrotliJSONEncoder()
//        let result = encoder.encode(data) // This returns Result<Data, Error>
//        
//        switch result {
//        case .success(let compressedData):
//            return compressedData
//        case .failure(let error):
//            print("Brotli compression failed: \(error)")
//            return nil
//        }
//    }
//
//    func performBrotliRequest(with payload: [String: Any]) -> AnyPublisher<OpenAIChatResponse, Error> {
//        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
//            return Fail(error: NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize JSON"]))
//                .eraseToAnyPublisher()
//        }
//        
//        guard let compressedData = compressDataBrotli(jsonData) else {
//            return Fail(error: NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress JSON data"]))
//                .eraseToAnyPublisher()
//        }
//        
//        guard let url = URL(string: chatURL) else {
//            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
//        }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer gxye69", forHTTPHeaderField: "Authorization")
//        request.setValue("br", forHTTPHeaderField: "Content-Encoding")
//        request.httpBody = compressedData // Send raw Brotli bytes
//        request.timeoutInterval = 60
//
//        // Send the request.
//        return Future { promise in
//            AF.request(request)
//                .validate()
//                .responseData { response in
//                    print("Full Response: \(String(describing: response.debugDescription))")
//
//                    if let data = response.data {
//                        print("Raw Response Data Size:", data.count)
//                        print("Response String: \(String(data: data, encoding: .utf8) ?? "unable to decode")")
//                    }
//
//                    if let statusCode = response.response?.statusCode {
//                        print("Response Status Code: \(statusCode)")
//                    }
//
//                    switch response.result {
//                    case .success(let data):
//                        do {
//                            let decodedResponse = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
//                            promise(.success(decodedResponse))
//                        } catch {
//                            print("Decoding Error: \(error)")
//                            promise(.failure(error))
//                        }
//                    case .failure(let error):
//                        print("Network Error: \(error)")
//                        promise(.failure(error))
//                    }
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//    
//    func sendMessage(messages: [ChatMessage]) -> AnyPublisher<OpenAIChatResponse, Error> {
//        let chatMessages = messages.map { message in
//            [
//                "role": message.sender == .me ? "user" : "assistant",
//                "content": message.content
//            ]
//        }
//        
//        let payload: [String: Any] = [
//            "model": "gpt-4o",
//            "messages": chatMessages
//        ]
//        
//        return performBrotliRequest(with: payload)
//    }
//    
//    func sendImageMessage(base64Image: String) -> AnyPublisher<OpenAIChatResponse, Error> {
//                let prompt = """
//                The picture provided is of a grocery receipt. You are an assistant whose job is to create recipes.
//                Your first task is to read through this receipt and create a list of ingredients strictly from the receipt.
//                There are a certain number of ingredients that can be labeled as "Common Household Ingredients", which I have provided below:
//                Common Household Ingredients:
//                "Pantry Basics:
//                    - Flour (all-purpose)
//                    - Sugar (granulated, brown)
//                    - Salt (table, kosher)
//                    - Black pepper
//                    - Baking soda
//                    - Baking powder
//                    - Vanilla extract
//                    - Cooking oils (vegetable, olive)
//                    - Vinegar (white, apple cider)
//                Seasonings/Spices:
//                    - Garlic powder
//                    - Onion powder
//                    - Cinnamon
//                    - Paprika
//                    - Red pepper flakes
//                    - Italian seasoning
//                    - Bay leaves
//                    - Dried oregano
//                    - Dried basil
//                    - Ground cumin
//                Refrigerator Staples:
//                    - Butter
//                    - Eggs
//                    - Milk
//                    - Mustard
//                    - Mayonnaise
//                    - Ketchup
//                    - Soy sauce
//                    - Hot sauce
//                    - Worcestershire sauce
//                Basic Produce:
//                    - Garlic
//                    - Onions
//                    - Lemons/Limes (these are borderline - some might not always have them)
//                Please create a combined list of all of the items from the receipt and this Common Household Ingredients list. Do not print out this list.
//                Now, please generate an array of 1 recipe in JSON format matching the following structure:
//                [
//                  {
//                    "name": "Recipe Name",
//                    "duration": "Cooking Time in minutes",
//                    "difficulty": "Easy/Medium/Hard",
//                    "ingredients": ["Ingredient 1", "Ingredient 2", "..."],
//                    "instructions": ["Step 1", "Step 2", "..."]
//                  },
//                ]
//                Ensure that the JSON is strictly valid and can be parsed by a JSON decoder. The response should only contain the JSON array of recipes without any additional text, headers, backticks, or symbols. Do not add any markdown formatting.
//                """
//
//        let payload: [String: Any] = [
//            "model": "gpt-4o",
//            "messages": [
//                [
//                    "role": "user",
//                    "content": "\(prompt)\n\ndata:image/jpeg;base64,\(base64Image)"
//                ]
//            ],
//            "max_tokens": 500
//        ]
//        print("payload size: \(payload.description.utf8.count)")
//        return performBrotliRequest(with: payload)
//    }
//    
//    func resizeImage(image: UIImage, targetWidth: CGFloat) -> UIImage? {
//        let scale = targetWidth / image.size.width
//        let targetHeight = image.size.height * scale
//        let newSize = CGSize(width: targetWidth, height: targetHeight)
//        
//        let renderer = UIGraphicsImageRenderer(size: newSize)
//        return renderer.image { _ in
//            image.draw(in: CGRect(origin: .zero, size: newSize))
//        }
//    }
//}
