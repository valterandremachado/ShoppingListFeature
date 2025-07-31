import Foundation

@MainActor
final class ShoppingListServerService {
    // MARK: - Properties
    private let apiClient = HTTPClient.shared

    // MARK: - Initialization
    init() { }

    // MARK: Methods

    // MARK: READ
    func fetchAllItems() async throws -> [ShoppingItemServerModel] {
        return try await apiClient.request(
            endpoint: .getShoppingItems,
            responseType: [ShoppingItemServerModel].self
        )
    }

    // MARK: CREATE
    func createItem(
        _ item: ShoppingItemServerModel
    ) async throws -> ShoppingItemServerModel {
        let data = try JSONEncoder().encode(item)
        return try await apiClient.request(
            endpoint: .createShoppingItem(data: data),
            responseType: ShoppingItemServerModel.self
        )
    }

    // MARK: UPDATE
    func updateItem(
        _ item: ShoppingItemServerModel
    ) async throws -> ShoppingItemServerModel {
        let data = try JSONEncoder().encode(item)
        return try await apiClient.request(
            endpoint: .updateShoppingItem(id: item.id, data: data),
            responseType: ShoppingItemServerModel.self
        )
    }

    // MARK: DELETE
    func deleteItem(
        _ item: ShoppingItemServerModel
    ) async throws {
        try await apiClient.request(
            endpoint: .deleteShoppingItem(id: item.id),
            responseType: EmptyResponse.self
        )
    }
}
