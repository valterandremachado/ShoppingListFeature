import Foundation

enum APIEndpoint {
    case getShoppingItems
    case createShoppingItem
    case updateShoppingItem(String)
    case deleteShoppingItem(String)

    // BaseURL
    static let apiBaseURL = "https://55kgy.wiremockapi.cloud"
    
    // Path prefix
    static let apiPathPrefix = "/api/shopping-items"

    var path: String {
        switch self {
        case .getShoppingItems, .createShoppingItem:
            return Self.apiPathPrefix
        case .updateShoppingItem(let id), .deleteShoppingItem(let id):
            return "\(Self.apiPathPrefix)/\(id)"
        }
    }

    var method: String {
        switch self {
        case .getShoppingItems:
            return "GET"
        case .createShoppingItem:
            return "POST"
        case .updateShoppingItem:
            return "PUT"
        case .deleteShoppingItem:
            return "DELETE"
        }
    }

    var request: URLRequest {
        let url = URL(string: Self.apiBaseURL)!.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method

        if method == "POST" || method == "PUT" {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }
}