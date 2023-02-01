import SwiftUI

class RendererView {
    private static var _metalView: MetalView!
    public static var gameViewController: NSViewController!
    public static var gameStoryboard: NSStoryboard!
    public static var metalView: MetalView {
        if RendererView._metalView != nil {
            return RendererView._metalView
        }
        
        RendererView._metalView = MetalView()
        return RendererView._metalView
    }
}

struct MetalView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        RendererView.gameStoryboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        RendererView.gameViewController = RendererView.gameStoryboard.instantiateController(withIdentifier: "Content") as? NSViewController
        return RendererView.gameViewController
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // Update the view and controller here
    }
}

