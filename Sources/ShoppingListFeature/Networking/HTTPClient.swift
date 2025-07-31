import Foundation

final class HTTPClient: @unchecked Sendable {
    static let shared = HTTPClient()
    private init() {}
    
    func request<T: Decodable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: endpoint.request)
        if let httpResponse = response as? HTTPURLResponse {
            print("Status code: \(httpResponse.statusCode)")
        }
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.unknownError("Invalid response")
        }
        
        // EmptyResponse and data is empty
        if T.self == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! T
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            print("Decoding failed with error: \(error)")
            throw APIError.decodingError(error.localizedDescription)
        }
    }
}

// MARK: - EmptyResponse
struct EmptyResponse: Decodable {}
