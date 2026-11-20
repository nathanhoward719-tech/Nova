import SwiftUI

@main
struct NovaApp: App {
    @StateObject private var model = BrowserModel()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(model)
        }
    }
}
