# Architecture Decisions

## Summary

The Shopping List Feature is architected as a modular SwiftUI application with a clear separation of concerns and an emphasis on offline-first capability, data consistency, and maintainability. The architecture is organized into distinct layers:

- **UI Layer:** Built with reusable SwiftUI views ([`ShoppingListView`](Sources/ShoppingListFeature/Views/ShoppingListView.swift), [`ShoppingItemRow`](Sources/ShoppingListFeature/Views/ShoppingItemRow.swift)), supporting search, sort, filter, and inline editing.
- **ViewModel Layer:** The [`ShoppingListViewModel`](Sources/ShoppingListFeature/ViewModels/ShoppingListViewModel.swift) manages UI state, orchestrates CRUD operations, and triggers synchronization.
- **Persistence Layer:** Local data is managed with Realm via [`ShoppingListLocalService`](Sources/ShoppingListFeature/Services/ShoppingListLocalService.swift) and [`ShoppingItemLocalModel`](Sources/ShoppingListFeature/Models/ShoppingItemLocalModel.swift), supporting soft deletes, sync flags, and efficient local queries.
- **Networking Layer:** All server communication is abstracted through [`ShoppingListServerService`](Sources/ShoppingListFeature/Services/ShoppingListServerService.swift), [`HTTPClient`](Sources/ShoppingListFeature/Networking/HTTPClient.swift), and endpoint definitions ([`Endpoints`](Sources/ShoppingListFeature/Networking/Endpoints.swift)).
- **Sync Layer:** The [`SyncService`](Sources/ShoppingListFeature/Services/SyncService.swift) implements a last-write-wins strategy, reconciling local and remote changes, handling deletions, and ensuring eventual consistency. It uses Combine for background sync and change observation.
- **Utilities:** Extensions ([`DateFormatter+Extensions`](Sources/ShoppingListFeature/Utils/DateFormatter+Extensions.swift), [`String+Extensions`](Sources/ShoppingListFeature/Utils/String+Extensions.swift)) provide consistent date and string formatting for serialization and parsing.
- **Testing:** The modular design and clear separation of services and models allow for straightforward unit testing of business logic and state management.

## Rejected Alternatives

### 1. Using Core Data for Local Persistence

**Reason Rejected:**  
Core Data was considered for local storage due to its deep integration with Apple platforms. However, Realm was chosen for its simpler API, easier handling of background writes, live updates, and suitability for rapid prototyping and real-time features.

### 2. Using a Dependency Injection Framework

**Reason Rejected:**  
A full-featured dependency injection (DI) framework (such as Resolver or Swinject) was considered to manage service and model dependencies. However, manual dependency injection was chosen for this project because it is easier to implement, introduces less complexity, and is more appropriate for a small project or prototype. While manual injection can become verbose in larger codebases, it keeps the setup explicit and transparent for this scope.