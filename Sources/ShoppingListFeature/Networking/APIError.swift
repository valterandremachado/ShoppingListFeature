import Foundation

enum APIError: Error, LocalizedError {
    case networkError(String)
    case decodingError(String)
    case serverError(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .decodingError(let message):
            return "Decoding Error: \(message)"
        case .serverError(let message):
            return "Server Error: \(message)"
        case .unknownError(let message):
            return "Unknown Error: \(message)"
        }
    }
}