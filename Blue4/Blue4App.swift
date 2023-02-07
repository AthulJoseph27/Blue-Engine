import SwiftUI

@main
struct Blue4App: App {
    
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        Engine.start(device: device)
        RendererManager.initialize()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1080, minHeight: 720)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
