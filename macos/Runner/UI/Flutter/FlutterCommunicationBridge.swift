import FlutterMacOS

enum FlutterBridgingMethod: String {
    case sendMessage = "send_message"
}

enum FlutterPage: String {
    case Settings = "Settings"
    case RenderImage = "RenderImage"
    case RenderAnimation = "RenderAnimation"
}

class FlutterCommunicationBridge: NSObject, FlutterPlugin, FlutterStreamHandler {
    static var METHOD_CHANNEL_NAME: String = "flutter_method_channel"
    static var EVENT_CHANNEL_NAME: String = "flutter_event_channel"
    private var eventSink: FlutterEventSink?
    
    // From Flutter
    public static func register(with registrar: FlutterPluginRegistrar) {}
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == FlutterBridgingMethod.sendMessage.rawValue {
            if let args = decodeArguments(call.arguments) as [String: Any]? {
                print("Received message from Flutter: \(args)")
                result(nil)
            } else {
                result(FlutterError(code: "argument_error", message: "Invalid argument", details: nil))
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    // To Flutter
    
    func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    func setPage(page: FlutterPage) {
        let argument = ["page" : page.rawValue]
        sendEvent(arguments: argument)
    }
    
    func sendEvent(arguments: [String: Any]) {
        self.eventSink?(encodeArguments(arguments))
    }
    
    // Helper Functions
    private func encodeArguments(_ argument: [String: Any]) -> String {
        
        let jsonData = try? JSONSerialization.data(withJSONObject: argument)
        
        if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        
        return ""
    }
    
    private func decodeArguments(_ argument: Any?) -> [String: Any] {
        if argument == nil {
            return [:]
        }
        
        let jsonString = argument as! String
        let jsonData = jsonString.data(using: .utf8)!
        
        do {
            if let dictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                print(dictionary)
                return dictionary
            }
        } catch {
            print("Error converting JSON data to dictionary: \(error.localizedDescription)")
        }
        
        return [:]
    }
}
