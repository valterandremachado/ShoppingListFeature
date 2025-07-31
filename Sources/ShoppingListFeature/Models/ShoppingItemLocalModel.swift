import Foundation
import RealmSwift

final class ShoppingItemLocalModel: Object, Identifiable {
    @Persisted var id: String = UUID().uuidString
    @Persisted var name: String
    @Persisted var quantity: Int64
    @Persisted var note: String?
    @Persisted var needsSync: Bool = false
    @Persisted var isPurchased: Bool = false
    @Persisted var isDeletedLocally: Bool = false
    @Persisted var createdAt: Date = Date()
    @Persisted var updatedAt: Date = Date()

    override class func primaryKey() -> String? {
        return "id"
    }
    
    public convenience init(
        name: String, 
        quantity: Int64, 
        note: String? = nil
    ) {
        self.init()
        self.name = name
        self.quantity = quantity
        self.note = note
    }
}