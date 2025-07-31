import SwiftUI
import RealmSwift

public struct ShoppingListView: View {
    // MARK: Properties
    @StateObject private var viewModel: ShoppingListViewModel

    // MARK: Initialization
    public init(
        localService: ShoppingListLocalService = ShoppingListLocalService(),
        serverService: ShoppingListServerService = ShoppingListServerService()
    ) {
        let syncService = SyncService(localService: localService, serverService: serverService)
        _viewModel = StateObject(
            wrappedValue: ShoppingListViewModel(
                localService: localService,
                serverService: serverService,
                syncService: syncService
            )
        )
    }

    // MARK: View Body
}