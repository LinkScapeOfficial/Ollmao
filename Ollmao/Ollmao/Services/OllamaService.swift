import Foundation

actor OllamaService {
    static let shared = OllamaService()
    private let baseURL = "http://localhost:11434/api"
    
    private init() {}
    
    private func formatContext(_ messages: [ChatMessage]) -> String {
        messages.map { message in
            switch message.role {
                case .user: return "Human: \(message.content)"
                case .assistant: return "Assistant: \(message.content)"
                case .system: return "System: \(message.content)"
            }
        }.joined(separator: "\n\n")
    }
    
    private func cleanResponse(_ response: String) -> String {
        // Remove any "Assistant:" or "Human:" prefixes from the response
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.lowercased().hasPrefix("assistant:") {
            return String(cleaned.dropFirst("assistant:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return cleaned
    }
    
    func generateResponse(prompt: String, messages: [ChatMessage], model: String = "deepseek-r1:8b") async throws -> AsyncThrowingStream<String, Error> {
        guard let url = URL(string: "\(baseURL)/generate") else {
            throw URLError(.badURL)
        }
        
        // Include previous messages in the prompt
        let context = messages.isEmpty ? "" : formatContext(messages) + "\n\n"
        let fullPrompt = context + "Human: " + prompt + "\n\nAssistant:"
        
        let body: [String: Any] = [
            "model": model,
            "prompt": fullPrompt,
            "stream": true
        ]
        
        print("Sending request to Ollama with body: \(body)")
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        print("Request JSON: \(String(data: jsonData, encoding: .utf8) ?? "")")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    print("Starting stream request to URL: \(url.absoluteString)")
                    let (stream, response) = try await URLSession.shared.bytes(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw URLError(.badServerResponse)
                    }
                    
                    print("Got response with status code: \(httpResponse.statusCode)")
                    
                    if !(200...299).contains(httpResponse.statusCode) {
                        var errorMessage = "HTTP Error \(httpResponse.statusCode)"
                        for try await line in stream.lines {
                            print("Error response line: \(line)")
                            if let data = line.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let error = json["error"] as? String {
                                errorMessage = error
                                break
                            }
                        }
                        throw NSError(domain: "OllamaError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    }
                    
                    var hasReceivedContent = false
                    var isFirstChunk = true
                    
                    for try await line in stream.lines {
                        print("Received line: \(line)")
                        
                        guard let data = line.data(using: .utf8) else {
                            print("Could not convert line to data: \(line)")
                            continue
                        }
                        
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                                print("Parsed JSON: \(json)")
                                if let response = json["response"] as? String {
                                    if !response.isEmpty {
                                        hasReceivedContent = true
                                        
                                        // Only clean the first chunk to remove potential "Assistant:" prefix
                                        let processedResponse = isFirstChunk ? cleanResponse(response) : response
                                        isFirstChunk = false
                                        
                                        continuation.yield(processedResponse)
                                    }
                                }
                                
                                if let done = json["done"] as? Bool, done {
                                    print("Stream completed")
                                    if !hasReceivedContent {
                                        throw NSError(domain: "OllamaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model failed to generate a response. Please try again."])
                                    }
                                    continuation.finish()
                                    return
                                }
                            }
                        } catch {
                            print("Failed to parse JSON: \(error)")
                            print("Raw data: \(String(data: data, encoding: .utf8) ?? "")")
                            continue
                        }
                    }
                    
                    if !hasReceivedContent {
                        throw NSError(domain: "OllamaError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response received from the model"])
                    }
                    continuation.finish()
                } catch {
                    print("Stream error: \(error)")
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    func listModels() async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/tags") else {
            throw URLError(.badURL)
        }
        
        print("Fetching models from URL: \(url.absoluteString)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        print("Models response status code: \(httpResponse.statusCode)")
        print("Models response data: \(String(data: data, encoding: .utf8) ?? "")")
        
        if !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }
        
        struct ModelResponse: Codable {
            let models: [Model]
            
            struct Model: Codable {
                let name: String
            }
        }
        
        let modelResponse = try JSONDecoder().decode(ModelResponse.self, from: data)
        let models = modelResponse.models.map { $0.name }
        print("Available models: \(models)")
        return models
    }
}
