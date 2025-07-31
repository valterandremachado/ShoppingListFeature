import Foundation
import RealmSwift
import Combine

final class ShoppingListLocalService {
    private let realm: Realm
    private var cancellables = Set<AnyCancellable>()
    let changesPublisher = PassthroughSubject<Void, Never>()

    // Initialize Realm
    init() throws {
        realm = try Realm()
    }

    // MARK: READ
    func getAllItems(includeSoftDeleted: Bool) -> [ShoppingItemLocalModel] {
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
        _ item: ShoppingItemLocalModel,
        with newName: String,
        newQuantity: Int64,
        newNote: String? = nil
    ) throws {

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
        let items = serverItems.map { serverItem in
            let localItem = ShoppingItemLocalModel()
            localItem.id = serverItem.id
            localItem.name = serverItem.name
            localItem.quantity = serverItem.quantity
            localItem.note = serverItem.note
            localItem.isPurchased = serverItem.isPurchased
            localItem.createdAt = serverItem.createdAt.toDate() ?? Date()
            localItem.updatedAt = serverItem.updatedAt?.toDate() ?? Date()
            return localItem
        }
        // Write to Realm
        try realm.write {
            realm.add(items, update: .modified)
        }
    }

    // Local Changes Publisher
    private func notifyChanges() {
        changesPublisher.send(())
    }
}