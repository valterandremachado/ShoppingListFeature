import Foundation

struct ShoppingItemServerModel: Codable, Identifiable {
    var id: String
    var name: String
    var quantity: Int64
    var note: String?
    var isPurchased: Bool
    var createdAt: String
    var updatedAt: String
}