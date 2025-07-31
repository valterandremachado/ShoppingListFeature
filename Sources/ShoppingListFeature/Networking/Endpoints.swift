import Foundation

// MARK: - APIPath
enum APIPath: String {
    case shoppingItems = "/api/shopping-items"

    func url(forBase base: APIBaseURL) -> URL {
        return base.baseURL.appendingPathComponent(self.rawValue)
    }

    func url(withID id: String, forBase base: APIBaseURL) -> URL {
        return base.baseURL.appendingPathComponent("\(self.rawValue)/\(id)")
    }
}

// MARK: - APIBaseURL
enum APIBaseURL {
    case wiremock

    var baseURL: URL {
        switch self {
        case .wiremock:
            return URL(string: "https://55kgy.wiremockapi.cloud")!
        }
    }
}

// MARK: - APIEndpoint
enum APIEndpoint {
    case getShoppingItems
    case createShoppingItem(data: Data)
    case updateShoppingItem(id: String, data: Data)
    case deleteShoppingItem(id: String)

    var request: URLRequest {
        let baseUrl = APIBaseURL.wiremock
        var request: URLRequest

        switch self {
        case .getShoppingItems:
            let url = APIPath.shoppingItems.url(forBase: baseUrl)
            request = URLRequest(url: url)
            request.httpMethod = "GET"

        case .createShoppingItem(let data):
            let url = APIPath.shoppingItems.url(forBase: baseUrl)
            request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data

        case .updateShoppingItem(let id, let data):
            let url = APIPath.shoppingItems.url(withID: id, forBase: baseUrl)
            request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.httpBody = data

        case .deleteShoppingItem(let id):
            let url = APIPath.shoppingItems.url(withID: id, forBase: baseUrl)
            request = URLRequest(url: url)
            request.httpMethod = "DELETE"
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}
