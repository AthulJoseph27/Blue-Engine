import MetalKit
import simd
import os

class RendererManager {
    private static let rendererCount = RendererType.allCases.count
    private static let counterView = NSLabel(frame: NSRect(x: 10, y: 10, width: 150, height: 50))
    private static var display = { (value: Double) -> Void in
        counterView.stringValue = String(format: "MRays/s: %.3f", value / 1_000_000)
    }
    private static var storyboards: [RenderViewPortType : NSStoryboard] = [:]
    private static var gameViewControllers: [RenderViewPortType : GameViewController] = [:]
    private static var mtkViews: [RenderViewPortType : MTKView] = [:]
    private static var renderers: [RenderViewPortType: Renderer] = [:]
    private static var metalViews: [RenderViewPortType : MetalView] = [:]
    private static var viewPortToRendererMap: [RenderViewPortType : RendererType] = [
        .StaticRT : .StaticRT,
        .DynamicRT : .DynamicRT,
        .PhongShader : .PhongShader,
        .Render : .StaticRT
    ]
    private static var _controllSettings: [RenderViewPortType: ControllSensitivity] = [
        .StaticRT : ControllSensitivity(),
        .DynamicRT : ControllSensitivity(),
        .PhongShader : ControllSensitivity()
    ]
    private static var sceneType: GameScenes = .Sandbox
    private static var viewPortType: RenderViewPortType = .StaticRT
    private static var renderMode: RenderMode = .display
    private static var viewPortSettings: [RenderViewPortType : RenderingSettings] = [
        .StaticRT : RayTracingSettings(samples: 400, maxBounce: 4, alphaTesting: false),
        .DynamicRT : RayTracingSettings(samples: 400, maxBounce: 4, alphaTesting: false),
        .PhongShader : VertexShadingSettings()
    ]
    private static var postRenderingCallback: (() -> Void)?
    
    public static func initialize() {
        sceneType = .Sandbox
        viewPortType = .StaticRT
        SceneManager.initialize(scene: sceneType, rendererType: .StaticRT)
        
        CameraManager.setCamera(.Debug)
        
        counterView.stringValue = ""
        counterView.textColor = .white
        
        // Initializing all view ports other than viewports related to rendering image/animation
        let viewPorts = RenderViewPortType.allCases
        let renderers = RendererType.allCases
        
        for i in 0..<rendererCount {
            initializeViewPort(viewPortType: viewPorts[i], rendererType: renderers[i])
        }

        mtkViews[.StaticRT]!.isPaused = false
    }
    
    public static func getStoryboard(_ viewPortType: RenderViewPortType) -> NSStoryboard {
        return storyboards[viewPortType]!
    }
    
    public static func setStoryboard(viewPortType: RenderViewPortType, storyboard: NSStoryboard) {
        storyboards[viewPortType] = storyboard
    }
    
    public static func getGameViewController(_ viewPortType: RenderViewPortType) -> GameViewController {
        return gameViewControllers[viewPortType]!
    }
    
    public static func getMetalView(_ viewPortType: RenderViewPortType) -> MetalView {
        return metalViews[viewPortType]!
    }
    
    public static func setGameViewController(viewPortType: RenderViewPortType, gameViewController: GameViewController) {
        gameViewControllers[viewPortType] = gameViewController
    }
    
    public static func pauseAllRenderingLoop() {
        let viewPorts = RenderViewPortType.allCases
        
        for i in 0..<rendererCount {
            mtkViews[viewPorts[i]]!.isPaused = true
        }
    }
    
    public static func getRenderedTexture()->MTLTexture? {
        return renderers[.Render]!.renderedTexture
    }
    
    public static func currentRenderMode() -> RenderMode {
        return renderMode
    }
    
    public static func setRenderMode(settings: RenderingSettings, postRenderingCallback: @escaping () -> Void) {
        renderMode = .render
        CameraManager.lockCamera()
        self.postRenderingCallback = postRenderingCallback
    }
    
    public static func onRenderingComplete() {
        postRenderingCallback?()
        setDisplayMode(settings: viewPortSettings[viewPortType]!)
        self.postRenderingCallback = nil
    }
    
    public static func setDisplayMode(settings: RenderingSettings) {
        CameraManager.unlockCamera()
        renderMode = .display
        mtkViews[.Render]!.isPaused = true
//        self.postRenderingCallback = nil
    }
    
    public static func updateViewPortSettings(viewPortType: RenderViewPortType, settings: RenderingSettings) {
        viewPortSettings[viewPortType] = settings
        renderers[viewPortType]!.updateRenderSettings(settings: settings)
    }
    
    public static func updateCurrentScene(scene: GameScenes) {
        sceneType = scene
        SceneManager.setScene(scene)
        renderers[viewPortType]!.updateScene(sceneType: sceneType)
    }
    
    public static func updateViewPort(viewPortType: RenderViewPortType) {
        CameraManager.setCameraControllSensitivity(_controllSettings[viewPortType]!)
        
        if self.viewPortType == viewPortType {
            resumeRenderingLoop(viewPortType: viewPortType)
            return
        }
        
        self.viewPortType = viewPortType
        
        pauseAllRenderingLoop()
        SceneManager.updateRenderableScene(viewPortToRendererMap[viewPortType]!)
        resumeRenderingLoop(viewPortType: viewPortType)
    }
    
    public static func updateCameraControllSensitivity(viewPortType: RenderViewPortType, controllSettings: ControllSensitivity) {
        _controllSettings[viewPortType] = controllSettings
    }
    
    public static func initializeViewPort(viewPortType: RenderViewPortType, rendererType: RendererType) {
        let storyboard = NSStoryboard(name: "MetalView", bundle: Bundle.main)
        let gameViewController = storyboard.instantiateController(withIdentifier: "Content") as! GameViewController
        
        mtkViews[viewPortType] = (gameViewController.view as! MTKView)
        mtkViews[viewPortType]!.isPaused = true
        storyboards[viewPortType] = storyboard
        gameViewControllers[viewPortType] = gameViewController
        setRenderer(mtkView: mtkViews[viewPortType]!, rendererType: rendererType, viewPortType: viewPortType)
        renderers[viewPortType]!.updateRenderSettings(settings: viewPortSettings[viewPortType]!)
        metalViews[viewPortType] = MetalView(viewPortType)
//            mtkViews[viewPortType]!.addSubview(counterView)
    }
    
    public static func getRendererView(rendererType: RendererType, settings: RenderingSettings) -> MetalView {
        pauseAllRenderingLoop()
        
        storyboards[.Render] = NSStoryboard(name: "MetalView", bundle: Bundle.main)
        gameViewControllers[.Render] = (storyboards[.Render]!.instantiateController(withIdentifier: "Content") as! GameViewController)
        
        SceneManager.updateRenderableScene(rendererType)
        mtkViews[.Render] = (gameViewControllers[.Render]!.view as! MTKView)
        setRenderer(mtkView: mtkViews[.Render]!, rendererType: rendererType, viewPortType: .Render)
        renderers[.Render]!.switchToRenderMode(settings: settings)
        return MetalView(gameViewControllers[.Render]!)
    }
    
    private static func resumeRenderingLoop(viewPortType: RenderViewPortType) {
        renderers[viewPortType]!.onResume()
        renderers[viewPortType]!.updateViewPort()
        mtkViews[viewPortType]!.isPaused = false
    }
    
    private static func setRenderer(mtkView: MTKView, rendererType: RendererType, viewPortType: RenderViewPortType) {
        var renderer: Renderer!
        
        switch rendererType {
        case .PhongShader:
            do {
                renderer = try PhongRenderer(withMetalKitView: mtkView, displayCounter: display)
            } catch let error as NSError {
                print("ERROR::CREATE::VERTEX_RENERER__::\(error)")
            }
        default:
            do {
                renderer = try RayTracingRenderer(withMetalKitView: mtkView, displayCounter: display)
            } catch let error as NSError {
                print("ERROR::CREATE::RAY_TRACING_RENERER__::\(error)")
            }
        }
        
        if renderer == nil {
            return
        }
        
        renderers[viewPortType] = renderer
        renderer!.updateScene(sceneType: sceneType)
        mtkView.delegate = renderer!
        renderer!.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
        
    }
}
