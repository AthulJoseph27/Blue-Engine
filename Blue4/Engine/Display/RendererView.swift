import SwiftUI

struct MetalView: NSViewControllerRepresentable {
    var viewPortType: RenderViewPortType
    
    init(_ viewPortType: RenderViewPortType) {
        self.viewPortType = viewPortType
    }
    
    func makeNSViewController(context: Context) -> NSViewController {
        return RendererManager.getGameViewController(viewPortType)
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // Update the view and controller here
    }
}

