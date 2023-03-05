import Cocoa
import SwiftUI
import FlutterMacOS

//class MainFlutterWindow: NSWindow {
//  override func awakeFromNib() {
//    let flutterViewController = FlutterViewController.init()
//    let windowFrame = self.frame
//    self.contentViewController = flutterViewController
//    self.setFrame(windowFrame, display: true)
//
//    RegisterGeneratedPlugins(registry: flutterViewController)
//
//    super.awakeFromNib()
//  }
//}

struct WindowViewController: NSViewControllerRepresentable {
    let viewController: NSViewController
    
    func makeNSViewController(context: Context) -> NSViewController {
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
}

struct FlutterView: View {
    static var flutterViewController: FlutterViewController!
    static var communicationBridge: FlutterCommunicationBridge!
    
    static func initialize() {
        FlutterView.flutterViewController = FlutterViewController.init()
        communicationBridge = FlutterCommunicationBridge()
        setUpCommunicationBridge()
        RegisterGeneratedPlugins(registry: FlutterView.flutterViewController)
    }

    var body: some View {
        WindowViewController(viewController: FlutterView.flutterViewController)
    }
    
    private static func setUpCommunicationBridge() {
        let methodChannel = FlutterMethodChannel(name: FlutterCommunicationBridge.METHOD_CHANNEL_NAME, binaryMessenger: FlutterView.flutterViewController.engine.binaryMessenger)
        methodChannel.setMethodCallHandler(communicationBridge.handle)
        
        let eventChannel = FlutterEventChannel(name: FlutterCommunicationBridge.EVENT_CHANNEL_NAME, binaryMessenger: FlutterView.flutterViewController.engine.binaryMessenger)
        eventChannel.setStreamHandler(communicationBridge)
    }
}
