import SwiftUI

@main
struct Blue4App: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1080, minHeight: 720)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
