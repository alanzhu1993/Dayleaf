import DayleafCore
import Foundation

struct OpenAICompatibleClient {
    enum ClientError: LocalizedError {
        case invalidBaseURL
        case invalidResponse
        case requestFailed(Int, String)
        case emptyContent

        var errorDescription: String? {
            switch self {
            case .invalidBaseURL:
                return "AI Base URL 无效。"
            case .invalidResponse:
                return "AI 服务返回格式无法读取。"
            case .requestFailed(let statusCode, let body):
                if body.isEmpty {
                    return "AI 请求失败（HTTP \(statusCode)）。"
                }
                return "AI 请求失败（HTTP \(statusCode)）：\(body)"
            case .emptyContent:
                return "AI 没有返回日记内容。"
            }
        }
    }

    var urlSession: URLSession = .shared

    func generateJournal(settings: DayleafSettings, apiKey: String, prompt: JournalPrompt) async throws -> String {
        guard let baseURLText = settings.aiBaseURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              let model = settings.aiModel?.trimmingCharacters(in: .whitespacesAndNewlines),
              baseURLText.isEmpty == false,
              model.isEmpty == false,
              let endpoint = Self.chatCompletionsURL(from: baseURLText) else {
            throw ClientError.invalidBaseURL
        }

        let body = ChatCompletionRequest(
            model: model,
            messages: [
                Message(role: "system", content: prompt.system),
                Message(role: "user", content: prompt.user)
            ],
            temperature: 0.45
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClientError.requestFailed(httpResponse.statusCode, body)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              content.isEmpty == false else {
            throw ClientError.emptyContent
        }
        return content
    }

    private static func chatCompletionsURL(from baseURLText: String) -> URL? {
        guard var components = URLComponents(string: baseURLText) else {
            return nil
        }

        let trimmedPath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmedPath.hasSuffix("chat/completions") {
            return components.url
        }

        if trimmedPath.isEmpty {
            components.path = "/chat/completions"
        } else {
            components.path = "/" + trimmedPath + "/chat/completions"
        }
        return components.url
    }
}

private struct ChatCompletionRequest: Encodable {
    var model: String
    var messages: [Message]
    var temperature: Double
}

private struct Message: Codable {
    var role: String
    var content: String
}

private struct ChatCompletionResponse: Decodable {
    var choices: [Choice]
}

private struct Choice: Decodable {
    var message: Message
}
