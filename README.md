# ShoppingListFeature

## Installation 
To install this package use url `https://github.com/valterandremachado/ShoppingListFeature.git` in SPM

## Usage Example

```swift
import ShoppingListFeature

struct ContentView: View {
    let localService = ShoppingListLocalService()
    let serverService = ShoppingListServerService()
    
    var body: some View {
        ShoppingListView(
            localService: localService,
            serverService: serverService
        )
    }
}
```
