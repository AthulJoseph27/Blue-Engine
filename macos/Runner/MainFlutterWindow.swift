import Cocoa
import SwiftUI
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController.init()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}

struct WindowViewController: NSViewControllerRepresentable {
    let viewController: NSViewController
    
    func makeNSViewController(context: Context) -> NSViewController {
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

struct FlutterView: View {
    var flutterViewController: NSViewController?
    
    init() {
        flutterViewController = FlutterViewController.init()
        RegisterGeneratedPlugins(registry: flutterViewController as! FlutterViewController)
    }
    
    var body: some View {
        WindowViewController(viewController: flutterViewController!)
    }
    
}
