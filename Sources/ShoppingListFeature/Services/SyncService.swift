import Foundation
import RealmSwift
import Combine

@MainActor
final class SyncService {
    private let realm = try! Realm()
    private let localService: ShoppingListLocalService
    private let serverService: ShoppingListServerService
    private var cancellables = Set<AnyCancellable>()

    init(localService: ShoppingListLocalService, serverService: ShoppingListServerService) {
        self.localService = localService
        self.serverService = serverService

        // Startup local subscription with Combine
        startBackgroundSync()
    }

    // MARK: Subscribe to local changes and trigger sync
    func startBackgroundSync() {
        localService.changesPublisher
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.syncChanges() }
            .store(in: &cancellables)
    }

    // MARK: Sync changes between local and server
    func syncLastWriteWins() async {
    // MARK: - TODO: Implement the last-write-wins strategy for syncing

        // 1. Fetch remote and local items
        // 2. Handle local deletions first (delete on server, then local)
        // 3. Refresh local state after deletions
        // 4. Reconcile items present both locally and remotely
        // 5. Handle local-only items (not deleted)
        // 6. Handle remote-only items (not just deleted)
    }
}