import FlutterMacOS
import SwiftUI

enum FlutterBridgingMethod: String {
    case sendMessage = "send_message"
}

enum SwiftBridgingMethodName: String {
    case renderImage = "renderImage"
    case renderAnimation = "renderAnimation"
    case switchCamera = "switchCamera"
    case updateViewportSettings = "updateViewportSettings"
    case updateSceneSettings = "updateSceneSettings"
    case updateCameraSettings = "updateCameraSettings"
    case importScene = "importScene"
    case importSkybox = "importSkybox"
}

enum SwiftBridgingEvents: String {
    case setPage = "setPage"
    case updateCurrentScene = "updateCurrentScene"
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
        if let args = decodeArguments(call.arguments) as [String: Any]? {
            switch call.method {
                case SwiftBridgingMethodName.renderImage.rawValue:
                    SwiftBridgingMethods.renderImage(arguments: args)
                    result(true)
                    break
            case SwiftBridgingMethodName.renderAnimation.rawValue:
                SwiftBridgingMethods.renderAnimation(arguments: args)
                result(true)
                break
                case SwiftBridgingMethodName.updateViewportSettings.rawValue:
                    SwiftBridgingMethods.updateViewportSettings(arguments: args)
                    result(true)
                    break
                case SwiftBridgingMethodName.updateSceneSettings.rawValue:
                    SwiftBridgingMethods.updateScenetSettings(arguments: args)
                    result(true)
                    break
                case SwiftBridgingMethodName.importScene.rawValue:
                    let _result = SwiftBridgingMethods.importScene(arguments: args)
                    result(_result)
                    break
                case SwiftBridgingMethodName.importSkybox.rawValue:
                    let _result = SwiftBridgingMethods.importSkybox(arguments: args)
                    result(_result)
                    break
                case SwiftBridgingMethodName.switchCamera.rawValue:  SwiftBridgingMethods.switchCamera(arguments: args)
                    result(true)
                    break
                default:
                    result(FlutterMethodNotImplemented)
            }
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
        let argument = ["function" : SwiftBridgingEvents.setPage.rawValue, "page" : page.rawValue]
        sendEvent(arguments: argument)
    }
    
    func sendEvent(arguments: [String: Any]) {
        if(self.eventSink == nil) {
            print("Swift: Event Sink is nil")
        }
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
                return dictionary
            }
        } catch {
            print("Error converting JSON data to dictionary: \(error.localizedDescription)")
        }
        
        return [:]
    }
}

class SwiftBridgingMethods {
    
    static func renderImage(arguments: [String: Any]) {
        if RenderImageModel.rendering {
            return
        }
        
        let model = RenderImageModel(json: arguments)
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: model.resolution.x, height: model.resolution.y),
                              styleMask: [.titled, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        
        let rendererType = (model.renderEngine == .aurora) ? RendererType.StaticRT : RendererType.PhongShader
        window.center()
        window.title = "Rendering"
        window.contentView = NSHostingView(rootView: RendererManager.getRendererView(rendererType: rendererType, settings: model.getRenderingSettings()))
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        RendererManager.setRenderMode(settings: model.getRenderingSettings()) {
            model.saveRenderImage()
            DispatchQueue.main.async {
                RenderImageModel.rendering = false
                window.close()
            }
        }
    }
    
    static func renderAnimation(arguments: [String: Any]) {
        if RenderAnimationModel.rendering {
            return
        }
        
        let model = RenderAnimationModel(json: arguments)
        
        let camera =  CameraManager.currentCamera as! AnimationCamera
        var keyframes = camera.getKeyframes()
        
//        CameraManager.setCamera(.Debug)
        
        let offsetTime = keyframes[0].time
        
        if !keyframes.isEmpty {
            for i in 0..<keyframes.count {
                let frame = KeyFrame(time: keyframes[i].time - offsetTime, position: keyframes[i].position, rotation: keyframes[i].rotation)
                keyframes[i] = frame
            }
        }
        
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: model.resolution.x, height: model.resolution.y),
                              styleMask: [.titled, .miniaturizable],
                              backing: .buffered,
                              defer: false)
        
        window.center()
        window.title = "Rendering"
        
        let rendererType = (model.renderEngine == .aurora) ? RendererType.StaticRT : RendererType.PhongShader
        window.contentView = NSHostingView(rootView: RendererManager.getRendererView(rendererType: rendererType, settings: model.getRenderingSettings()))
        
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let renderingQueue = DispatchQueue(label: "com.Blue4.renderingQueue")
        
        renderingQueue.async {
            renderAnimationLoop(model: model, keyframes: keyframes, semaphore: semaphore, window: window)
        }
        
    }
    
    static func switchCamera(arguments: [String: Any]) {
        let recordMode = arguments["recordMode"] as? Bool ?? false
        
        if recordMode {
            CameraManager.setCamera(.Animation)
        } else {
            CameraManager.setCamera(.Debug)
        }
    }
    
    static func updateScenetSettings(arguments: [String: Any]) {
        SceneManager.updateSceneSettings(arguments: arguments)
    }
    
    static func updateViewportSettings(arguments: [String: Any]) {
        updateAuroraViewportSettings(arguments: arguments["aurora"] as? ([String: Any]))
        updateCometViewportSettings(arguments: arguments["comet"] as? ([String: Any]))
    }
    
    static func importScene(arguments: [String: Any]) -> Bool {
        do {
            if let filePath = arguments["filePath"] as? String {
                try MeshLibrary.loadMesh(filePath: filePath)
                updateScenetSettings(arguments: ["scene" : "Custom"])
                return true
            }
        } catch {}
        
        return false
    }
    
    static func importSkybox(arguments: [String: Any]) -> Bool {
        do {
            if let filePath = arguments["filePath"] as? String {
                try Skyboxibrary.loadSkyboxFromPath(path: filePath)
                updateScenetSettings(arguments: ["skybox" : "Custom"])
                return true
            }
        } catch {}
        
        return false
    }
    
    private static func updateAuroraViewportSettings(arguments: [String: Any]?) {
        if let json = arguments {
            
            if let bounce = json["maxBounce"] as? Int {
                let maxBounce = max(bounce, 1)
                let alphaTesting = json["alphaTesting"] as? Bool ?? false
                RendererManager.updateViewPortSettings(viewPortType: .StaticRT, settings: RayTracingSettings(maxBounce: maxBounce, alphaTesting: alphaTesting))
            }
            
            let settings = ControllSensitivity.fromJson(json: json["controlSensitivity"] as? [String: Any] ?? [:])
            
            RendererManager.updateCameraControllSensitivity(viewPortType: .StaticRT, controllSettings: settings)
            RendererManager.updateCameraControllSensitivity(viewPortType: .DynamicRT, controllSettings: settings)
        }
    }
    
    private static func updateCometViewportSettings(arguments: [String: Any]?) {
        if let json = arguments {
            
            let settings = ControllSensitivity.fromJson(json: json["controlSensitivity"] as? [String: Any] ?? [:])
            RendererManager.updateCameraControllSensitivity(viewPortType: .PhongShader, controllSettings: settings)
        }
    }
    
    private static func renderAnimationLoop(model: RenderAnimationModel, keyframes: [KeyFrame], semaphore: DispatchSemaphore, window: NSWindow) {
        
        let rendererType = (model.renderEngine == .aurora) ? RendererType.StaticRT : RendererType.PhongShader
        
        let deltaTime = 1.0 / Double(model.fps)
        let endTime = keyframes.last!.time
        
        var iter = 0
        var time = 0.0
        
        while(time <= endTime) {
            time += deltaTime
            iter += 1
            
            let keyframe = RenderAnimationModel.getKeyframeAt(at: time, keyframes: keyframes)
            
            CameraManager.currentCamera.position = keyframe.position
            CameraManager.currentCamera.rotation = keyframe.rotation
            
            
            RendererManager.setRenderMode(settings: model.getRenderingSettings()) {
                model.saveRenderImage()
                DispatchQueue.main.async {
                    window.contentView = NSHostingView(rootView: RendererManager.getRendererView(rendererType: rendererType, settings: model.getRenderingSettings()))
                    semaphore.signal()
                }
            }
            
            semaphore.wait()
        }
        
        RenderAnimationModel.rendering = false
        model.saveVideo()
        
        DispatchQueue.main.async {
            window.close()
        }
    }
}
