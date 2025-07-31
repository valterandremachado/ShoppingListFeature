import Foundation
import RealmSwift
import Combine

public class ShoppingListLocalService {
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    let changesPublisher = PassthroughSubject<Void, Never>()

    // Initialize Realm
    public init() {
        do {
            realm = try Realm()
        } catch {
            fatalError("Failed to initialize local db: \(error)")
        }
    }

    // MARK: READ
    func getAllItems(includeSoftDeleted: Bool = false) -> [ShoppingItemLocalModel] {
        let items = realm.objects(ShoppingItemLocalModel.self)
        return includeSoftDeleted ? Array(items) : Array(items.filter("isDeletedLocally == false"))
    }

    // MARK: CREATE
    func createItem(
        name: String, 
        quantity: Int64, 
        note: String? = nil
    ) throws -> ShoppingItemLocalModel {
        let item = ShoppingItemLocalModel(
            name: name, 
            quantity: quantity, 
            note: note
        )

        // Write to Realm
        try realm.write {
            item.needsSync = true
            realm.add(item)
        }
        notifyChanges()
        return item
    }

    // MARK: UPDATE
    func updateItem(
        with id: String,
        newName: String,
        newQuantity: Int64,
        newNote: String? = nil
    ) throws {

        guard let item = realm.object(
            ofType: ShoppingItemLocalModel.self,
            forPrimaryKey: id
        ) else { return }
        
        // Write to Realm
        try realm.write {
            item.name = newName
            item.quantity = newQuantity
            item.note = newNote
            item.updatedAt = Date()
            item.needsSync = true
        }
        notifyChanges()
    }

    // MARK: DELETE (Soft Delete)
    func deleteItem(itemId: String) throws {
        guard let item = realm.object(ofType: ShoppingItemLocalModel.self, forPrimaryKey: itemId) else {
            throw NSError(domain: "ShoppingListLocalService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Item not found"])
        }
        
        // Write to Realm
        try realm.write {
            item.isDeletedLocally = true
            item.needsSync = true
        }
        notifyChanges()
    }

    // Save items from server
    func saveItemsFromServer(_ items: [ShoppingItemServerModel]) throws {
        let items = items.map { serverItem in
            let localItem = ShoppingItemLocalModel()
            localItem.id = serverItem.id
            localItem.name = serverItem.name
            localItem.quantity = serverItem.quantity
            localItem.note = serverItem.note
            localItem.isPurchased = serverItem.isPurchased
            localItem.createdAt = serverItem.createdAt.toDate() ?? Date()
            localItem.updatedAt = serverItem.updatedAt.toDate() ?? Date()
            return localItem
        }
        // Write to Realm
        try realm.write {
            realm.add(items, update: .modified)
        }
    }

    // Toggle purchased status
    func togglePurchased(for id: String) throws {
        if let object = realm.object(ofType: ShoppingItemLocalModel.self, forPrimaryKey: id)?.thaw() {
            try realm.write {
                object.needsSync = true
                object.updatedAt = Date()
                object.isPurchased.toggle()
            }
            notifyChanges()
        }
    }
    
    // Get all items needing sync (including soft-deleted)
    func getItemsNeedingSync() -> [ShoppingItemLocalModel] {
        Array(realm.objects(ShoppingItemLocalModel.self).filter("needsSync == true"))
    }
    
    // Clear flags or hard-delete after successful sync
    func markItemSynced(_ item: ShoppingItemLocalModel) {
        try? realm.write {
            item.needsSync = false
            if item.isDeletedLocally {
                realm.delete(item)
            }
        }
    }
    
    // Local Changes Publisher
    private func notifyChanges() {
        changesPublisher.send(())
    }
}
