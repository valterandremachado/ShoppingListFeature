import Foundation

@MainActor
final class ShoppingListServerService {
    // MARK: - Properties
    private let apiClient: HTTPClient

    // MARK: - Initialization
    init(apiClient: APIClient.shared) {
        self.apiClient = apiClient
    }

    // MARK: Methods

    // MARK: READ
    func fetchAllItems() async throws -> [ShoppingItemLocalModel] {
        return try await apiClient.performRequest(
            endpoint: .getShoppingItems, 
            method: "GET"
        )
    }

    // MARK: CREATE
    func createItem(
        _ item: ShoppingItemLocalModel
    ) async throws -> ShoppingItemLocalModel {
        return try await apiClient.performRequest(
            endpoint: .createShoppingItem,
            method: "POST",
            body: item
        )
    }

    // MARK: UPDATE
    func updateItem(
        _ item: ShoppingItemLocalModel
    ) async throws -> ShoppingItemLocalModel {
        return try await apiClient.performRequest(
            endpoint: .updateShoppingItem(item.id),
            method: "PUT",
            body: item
        )
    }

    // MARK: DELETE
    func deleteItem(
        _ item: ShoppingItemLocalModel
    ) async throws {
        try await apiClient.performRequest(
            endpoint: .deleteShoppingItem(item.id),
            method: "DELETE"
        )
    }
}