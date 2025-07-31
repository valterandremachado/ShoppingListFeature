import Foundation
import RealmSwift
import Combine

@MainActor
final class SyncService {
    private let realm = try! Realm()
    private let localService: ShoppingListLocalService
    private let serverService: ShoppingListServerService
    private var cancellables = Set<AnyCancellable>()
    private var isSyncing = false

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
            .sink { [weak self] in
                guard let self = self else { return }
                Task {
                    await self.syncLastWriteWins()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Sync changes between local and server
    func syncLastWriteWins() async {
        // Sync safe guard - prevent overlapping syncs
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            // 1. Fetch remote and local items
            let remoteItems = try await serverService.fetchAllItems()
            let remoteDict = Dictionary(uniqueKeysWithValues: remoteItems.map { ($0.id, $0) })
            let localItems = localService.getAllItems(includeSoftDeleted: true)
            let localDict = Dictionary(uniqueKeysWithValues: localItems.map { ($0.id, $0) })
            
            var deletedRemoteIDs = Set<String>() // Track remote deletions
            
            // 2. Handle local deletions first (delete on server, then local)
            for (id, local) in localDict where local.isDeletedLocally {
                do {
                    try await serverService.deleteItem(id)
                } catch {
                    print("Warning: Failed to delete item \(id) on server: \(error)")
                }
                deletedRemoteIDs.insert(id)
                try await Task.sleep(nanoseconds: 300_000_000)
                // Use markItemSynced to ensure hard-delete
                localService.markItemSynced(local)
            }
            
            // 3. Refresh local state after deletions
            let currentLocalItems = localService.getAllItems()
            let currentLocalDict = Dictionary(uniqueKeysWithValues: currentLocalItems.map { ($0.id, $0) })
            
            // 4. Reconcile items present both locally and remotely
            for (id, remote) in remoteDict {
                guard let local = currentLocalDict[id] else { continue }
                let localUpdated = local.updatedAt
                let remoteUpdated = remote.updatedAt.toDate() ?? Date.distantPast
                
                if localUpdated > remoteUpdated {
                    // Local is newer: push to server
                    let serverModel = ShoppingItemServerModel(
                        id: local.id,
                        name: local.name,
                        quantity: local.quantity,
                        note: local.note,
                        isPurchased: local.isPurchased,
                        createdAt: DateFormatter.iso8601.string(from: local.createdAt),
                        updatedAt: DateFormatter.iso8601.string(from: local.updatedAt)
                    )
                    _ = try await serverService.updateItem(serverModel)
                    try realm.write { local.needsSync = false }
                } else if remoteUpdated > localUpdated {
                    // Remote is newer: update local
                    try realm.write {
                        local.name = remote.name
                        local.quantity = remote.quantity
                        local.note = remote.note
                        local.isPurchased = remote.isPurchased
                        local.createdAt = remote.createdAt.toDate() ?? local.createdAt
                        local.updatedAt = remote.updatedAt.toDate() ?? local.updatedAt
                        local.needsSync = false
                        local.isDeletedLocally = false
                    }
                } else {
                    // Timestamps equal: mark as synced
                    try realm.write { local.needsSync = false }
                }
            }
            
            // 5. Handle local-only items (not deleted)
            for (id, local) in currentLocalDict where remoteDict[id] == nil && !local.isDeletedLocally {
                let serverModel = ShoppingItemServerModel(
                    id: local.id,
                    name: local.name,
                    quantity: local.quantity,
                    note: local.note,
                    isPurchased: local.isPurchased,
                    createdAt: DateFormatter.iso8601.string(from: local.createdAt),
                    updatedAt: DateFormatter.iso8601.string(from: local.updatedAt)
                )
                _ = try await serverService.createItem(serverModel)
                try realm.write { local.needsSync = false }
            }
            
            // 6. Handle remote-only items (not just deleted)
            let refreshedLocalItems = localService.getAllItems(includeSoftDeleted: true)
            let refreshedLocalDict = Dictionary(uniqueKeysWithValues: refreshedLocalItems.map { ($0.id, $0) })
            for (id, remote) in remoteDict where refreshedLocalDict[id] == nil && !deletedRemoteIDs.contains(id) {
                let item = ShoppingItemLocalModel()
                item.id = remote.id
                item.name = remote.name
                item.quantity = remote.quantity
                item.note = remote.note
                item.isPurchased = remote.isPurchased
                item.createdAt = remote.createdAt.toDate() ?? Date()
                item.updatedAt = remote.updatedAt.toDate() ?? Date()
                item.needsSync = false
                item.isDeletedLocally = false
                try realm.write { realm.add(item, update: .modified) }
            }
        } catch {
            print("Sync error: \(error)")
        }
    }
}
