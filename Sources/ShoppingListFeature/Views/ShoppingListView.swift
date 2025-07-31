import SwiftUI
import RealmSwift

public struct ShoppingListView: View {
    // MARK: Enums
    private enum SortOption {
        case createdAsc, createdDesc, modAsc, modDesc
    }
    
    private enum FilterOption {
        case purchased, notPurchased
    }
    
    // MARK: - Properties
    
    // ViewModel
    @StateObject private var viewModel: ShoppingListViewModel
    
    // SearchBar Text
    @State private var searchText: String = ""
    
    // Sort and Filter
    @State private var showFilterSheet = false
    @State private var sortOption: SortOption = .createdAsc
    @State private var filterOption: FilterOption = .notPurchased
    
    // Add Item Alert
    @State private var showingAddAlert = false
    @State private var newName: String = ""
    @State private var newQuantity: String = ""
    @State private var newNote: String = ""
    
    // Edit Item Alert
    @State private var showingEditAlert = false
    @State private var selectedItem: ShoppingItemLocalModel?
    @State private var editName: String = ""
    @State private var editQuantity: String = ""
    @State private var editNote: String = ""
    
    // Validation Alert
    @State private var showValidationAlert = false
    @State private var validationAlertMessage = ""
    
    // MARK: Computed Properties
    private var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var allFilteredItems: [ShoppingItemLocalModel] {
        viewModel.filteredItems(searchText: searchText)
    }
    
    private var filteredItems: [ShoppingItemLocalModel] {
        switch filterOption {
        case .purchased:
            return allFilteredItems.filter { $0.isPurchased }
        case .notPurchased:
            return allFilteredItems.filter { !$0.isPurchased }
        }
    }
    
    private var filteredAndSortedItems: [ShoppingItemLocalModel] {
        var items = filteredItems
        switch sortOption {
        case .createdAsc:
            items.sort { $0.createdAt < $1.createdAt }
        case .createdDesc:
            items.sort { $0.createdAt > $1.createdAt }
        case .modAsc:
            items.sort { $0.updatedAt < $1.updatedAt }
        case .modDesc:
            items.sort { $0.updatedAt > $1.updatedAt }
        }
        return items
    }
    
    // MARK: Initialization
    public init(
        localService: ShoppingListLocalService,
        serverService: ShoppingListServerService
    ) {
        _viewModel = StateObject(
            wrappedValue: ShoppingListViewModel(
                serverService: serverService,
                localService: localService
            )
        )
    }
    
    // MARK: View Body
    public var body: some View {
        NavigationView {
            List {
                itemSection
            }
            .searchable(text: $searchText, prompt: "Search by name or note")
            .navigationBarTitle("Shopping List", displayMode: .inline)
            .navigationBarItems(
                leading: Button(action: {
                    viewModel.forceSync()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                },
                trailing: Button(action: {
                    showingAddAlert = true
                }) {
                    Image(systemName: "plus.circle")
                }
            )
            .onAppear {
                viewModel.loadItems()
            }
            .alert("Add Item", isPresented: $showingAddAlert) {
                addItemAlertContent
            } message: {
                Text("Enter item details")
            }
            .alert("Edit Item", isPresented: $showingEditAlert) {
                editItemAlertContent
            } message: {
                Text("Edit item details")
            }
            .modifier(ValidationAlertModifier(isPresented: $showValidationAlert, message: validationAlertMessage))
        }
    }
    
    @ViewBuilder
    private var itemSection: some View {
        Section {
            if filteredAndSortedItems.isEmpty {
                emptyStateView
            } else {
                ForEach(filteredAndSortedItems) { item in
                    ShoppingItemRow(
                        item: item,
                        onToggle: {
                            viewModel.toggleItemPurchased(item)
                        },
                        onRowTap: {
                            selectedItem = item
                            editName = item.name
                            editQuantity = String(item.quantity)
                            editNote = item.note ?? ""
                            showingEditAlert = true
                        }
                    )
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let item = filteredAndSortedItems[index]
                        try? viewModel.deleteItem(item)
                    }
                }
            }
        } header: {
            sectionHeader
        } footer: {
            EmptyView()
        }
    }

    private var emptyStateView: some View {
        Group {
            if isSearching {
                EmptyStateView(title: "No matching items found", systemImage: "magnifyingglass")
            } else {
                switch filterOption {
                case .purchased:
                    EmptyStateView(title: "No purchased items", systemImage: "checkmark.circle")
                case .notPurchased:
                    EmptyStateView(title: "No items to purchase", systemImage: "cart")
                }
            }
        }
    }
    
    private var sectionHeader: some View {
        HStack {
            Text("My Items")
                .font(.headline)
            Spacer()
            Menu {
                // Sort Menu Group
                Menu("Sort By") {
                    Button(action: { sortOption = .createdAsc }) {
                        Label("Created: Oldest First", systemImage: sortOption == .createdAsc ? "checkmark" : "")
                    }
                    Button(action: { sortOption = .createdDesc }) {
                        Label("Created: Newest First", systemImage: sortOption == .createdDesc ? "checkmark" : "")
                    }
                    Button(action: { sortOption = .modAsc }) {
                        Label("Updated: Oldest First", systemImage: sortOption == .modAsc ? "checkmark" : "")
                    }
                    Button(action: { sortOption = .modDesc }) {
                        Label("Updated: Newest First", systemImage: sortOption == .modDesc ? "checkmark" : "")
                    }
                }
                
                // Filter Menu Group
                Menu("Filter By") {
                    Button(action: { filterOption = .purchased }) {
                        Label("Purchased", systemImage: filterOption == .purchased ? "checkmark" : "")
                    }
                    Button(action: { filterOption = .notPurchased }) {
                        Label("Not Purchased", systemImage: filterOption == .notPurchased ? "checkmark" : "")
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .imageScale(.large)
            }
        }
        .textCase(nil)
        .padding(.bottom, 4)
        .padding(.top, -10)
    }
    
    private var addItemAlertContent: some View {
        Group {
            TextField("Name", text: $newName)
            TextField("Quantity", text: $newQuantity)
                .keyboardType(.numberPad)
            TextField("Note (Optional)", text: $newNote)
            
            Button("Add", action: handleAdd)
            Button("Cancel", role: .cancel, action: resetInputs)
        }
    }
    
    private var editItemAlertContent: some View {
        Group {
            TextField("Name", text: $editName)
            TextField("Quantity", text: $editQuantity)
                .keyboardType(.numberPad)
            TextField("Note (Optional)", text: $editNote)
            
            Button("Save", action: handleEdit)
            Button("Cancel", role: .cancel, action: resetEditInputs)
        }
    }
    
    private func handleAdd() {
        let trimmedName = newName.trimmingCharacters(in: .whitespaces)
        let trimmedQuantity = newQuantity.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showValidation(message: "Name is required.")
            return
        }
        guard let quantityValue = Int64(trimmedQuantity), quantityValue > 0 else {
            showValidation(message: "Quantity must be a positive number.")
            return
        }
        viewModel.addItem(name: trimmedName, quantity: quantityValue, note: newNote)
        resetInputs()
    }
    
    private func handleEdit() {
        guard let item = selectedItem else { return }
        let trimmedName = editName.trimmingCharacters(in: .whitespaces)
        let trimmedQuantity = editQuantity.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            showValidation(message: "Name is required.")
            return
        }
        guard let quantityValue = Int64(trimmedQuantity), quantityValue > 0 else {
            showValidation(message: "Quantity must be a positive number.")
            return
        }
        let itemNote = !editNote.isEmpty ? editNote : item.note
        viewModel.updateItem(
            item,
            newName: trimmedName,
            newQuantity: quantityValue,
            newNote: itemNote
        )
        resetEditInputs()
    }
    
    private func showValidation(message: String) {
        validationAlertMessage = message
        showValidationAlert = true
    }
    
    private func resetInputs() {
        newName = ""
        newQuantity = ""
        newNote = ""
    }
    
    private func resetEditInputs() {
        selectedItem = nil
        editName = ""
        editQuantity = ""
        editNote = ""
    }
}

// Modularized Validation Alert Modifier
struct ValidationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    
    func body(content: Content) -> some View {
        content
            .alert("Validation Error", isPresented: $isPresented) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(message)
            }
    }
}


private struct EmptyStateView: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.gray.opacity(0.7))
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding()
    }
}
