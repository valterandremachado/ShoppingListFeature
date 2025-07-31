import Foundation
import RealmSwift
import Combine

@MainActor
final class ShoppingListViewModel: ObservableObject {
    // MARK: - Properties
    @Published var items: [ShoppingItemLocalModel] = []
    private var cancellables = Set<AnyCancellable>()

    private let serverService: ShoppingListServerService
    private let localService: ShoppingListLocalService
    private let syncService: SyncService

    // MARK: - Initialization
    init(
        serverService: ShoppingListServerService = ShoppingListServerService(),
        localService: ShoppingListLocalService = ShoppingListLocalService(),
        syncService: SyncService = SyncService()
    ) {
        self.serverService = serverService
        self.localService = localService
        self.syncService = syncService  

        // Startup background sync
        syncService.startBackgroundSync()
        
        // Subscribe to local changes
        localService.changesPublisher
            .sink { [weak self] in
                guard let self = self else { return }
                self.items = self.localService.getAllItems()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    // MARK: - CRUD

    // MARK: READ
    func loadItems() {
        // Load locally first so UI shows instantly
        items = localService.getAllItems()

        // Try to sync from server in background
        Task {
            do {
                let serverItems = try await serverService.fetchAllItems()
                // Update local service with server items
                try localService.updateItemsFromServer(serverItems)
                // Refresh items from local service
                items = localService.getAllItems()
            } catch {
                print("Failed to fetch items from server: \(error)")
            }
        }
    }

    // MARK: CREATE
    func addItem(
        name: String, 
        quantity: Int64, 
        note: String? = nil
    ) {
        do {
            let newItem = try localService.createItem(
                name: name, 
                quantity: quantity, 
                note: note
            )
            // Refresh items from local service
            items = localService.getAllItems()
        } catch {
            print("Failed to create item locally: \(error)")
        }
    }

    // MARK: UPDATE
    func updateItem(
        _ item: ShoppingItemLocalModel, 
        newName: String, 
        newQuantity: Int64, 
        newNote: String? = nil
    ) {
        do {
            try localService.updateItem(
                item, 
                with: newName, 
                newQuantity: newQuantity, 
                newNote: newNote
            )
            // Refresh items from local service
            items = localService.getAllItems()
        } catch {
            print("Failed to update item locally: \(error)")
        }
    }

    // MARK: DELETE
    func deleteItem(_ item: ShoppingItemLocalModel) {
        do {
            try localService.deleteItem(itemId: item.id)
            // Refresh items from local service
            items = localService.getAllItems()
        } catch {
            print("Failed to delete item locally: \(error)")
        }
    }

    // MARK: - Helpers

    // Toggle item purchased status
    func toggleItemPurchased(_ item: ShoppingItemLocalModel) {
        do {
            try localService.togglePurchased(for: item.id)
            items = localService.getAllItems()
        } catch {
            print("Failed to toggle purchased: \(error)")
        }
    }

    // Filter out locally (soft) deleted items
    func filterItems( _ items: [ShoppingItemLocalModel]) -> [ShoppingItemLocalModel] {
        return items.filter { !$0.isDeletedLocally }
    }

    // Filter Items based on searchText
    func filteredItems(searchText: String) -> [ShoppingItemLocalModel] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            ($0.note?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    // Force sync with server
    func forceSync() {
        Task {
            await syncService.syncLastWriteWins()
            items = localService.getAllItems()
        }
    }
}
