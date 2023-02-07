import MetalKit
import simd
import os

class RendererManager {
    private static let counterView = NSLabel(frame: NSRect(x: 10, y: 10, width: 150, height: 50))
    private static var display = { (value: Double) -> Void in
        counterView.stringValue = String(format: "MRays/s: %.3f", value / 1_000_000)
    }
    private static var storyboards: [RenderViewPortType : NSStoryboard] = [:]
    private static var gameViewControllers: [RenderViewPortType : GameViewController] = [:]
    private static var mtkViews: [RenderViewPortType : MTKView] = [:]
    private static var renderers: [RenderViewPortType: Renderer] = [:]
    
    private static var sceneType: GameScenes = .Sandbox
    private static var viewPortType: RenderViewPortType = .StaticRT
    private static var renderMode: RenderMode = .display
    private static var viewPortSettings: [RenderViewPortType : RenderingSettings] = [
        .StaticRT : RayTracingSettings(maxBounce: 4),
        .DynamicRT : RayTracingSettings(maxBounce: 4),
        .VertexShader : VertexShadingSettings()
    ]
    private static var postRenderingCallback: (() -> Void)?
    
    public static func initialize() {
        sceneType = .Sandbox
        SceneManager.initialize(scene: sceneType)
        
        viewPortType = .StaticRT
        RenderViewPortManager.setViewPort(viewPortType)
        
        setupDefaultCamera()
        
        counterView.stringValue = ""
        counterView.textColor = .white
        
        for viewPortType in RenderViewPortType.allCases {
            initializeViewPort(viewPortType)
        }
        
        mtkViews[.StaticRT]!.isPaused = false
    }
    
    public static func getStoryboard(_ viewPortType: RenderViewPortType) -> NSStoryboard {
        return storyboards[viewPortType]!
    }
    
    public static func getGameViewController(_ viewPortType: RenderViewPortType) -> GameViewController {
        return gameViewControllers[viewPortType]!
    }
    
    public static func currentRenderer() -> Renderer? {
        return renderers[viewPortType]
    }
    
    public static func pauseAllRenderingLoop() {
        for vp in RenderViewPortType.allCases {
            mtkViews[vp]!.isPaused = true
        }
    }
    
    public static func resumeRenderingLoop(viewPortType: RenderViewPortType) {
        mtkViews[viewPortType]!.isPaused = false
    }
    
    public static func resumeRenderingLoop() {
        mtkViews[viewPortType]!.isPaused = false
    }
    
    public static func getRenderedTexture()->MTLTexture? {
        return renderers[viewPortType]!.renderedTexture
    }
    
    public static func currentRenderMode() -> RenderMode {
        return renderMode
    }
    
    public static func setRenderMode(settings: RenderingSettings, postRenderingCallback: @escaping () -> Void) {
        renderMode = .render
        renderers[viewPortType]!.switchToRenderMode(settings: settings)
        self.postRenderingCallback = postRenderingCallback
    }
    
    public static func onRenderingComplete() {
        postRenderingCallback!()
        setDisplayMode(settings: viewPortSettings[viewPortType]!)
    }
    
    public static func setDisplayMode(settings: RenderingSettings) {
        renderMode = .display
        renderers[viewPortType]!.switchToDisplayMode(settings: viewPortSettings[viewPortType]!)
//        mtkViews[viewPortType]!.isPaused = false
//        self.postRenderingCallback = nil
    }
    
    public static func updateViewPortSettings(viewPortType: RenderViewPortType, settings: RenderingSettings) {
        viewPortSettings[viewPortType] = settings
        renderers[viewPortType]!.updateRenderSettings(settings: settings)
    }
    
    public static func updateCurrentScene(scene: GameScenes) {
        sceneType = scene
        SceneManager.setScene(scene)
        RenderViewPortManager.setViewPort(viewPortType)
        renderers[viewPortType]!.updateScene(sceneType: sceneType)
    }
    
    public static func updateViewPort(viewPortType: RenderViewPortType) {
        if self.viewPortType == viewPortType {
            return
        }
        
        self.viewPortType = viewPortType
        
        pauseAllRenderingLoop()
        RenderViewPortManager.setViewPort(viewPortType)
        resumeRenderingLoop(viewPortType: viewPortType)
    }
    
    private static func setupDefaultCamera() {
        let camera = DebugCamera()
        camera.position = SIMD3<Float>(0, 1, 3.38)
        CameraManager.registerCamera(camera: camera)
        CameraManager.setCamera(.Debug)
    }
    
    private static func initializeViewPort(_ viewPortType: RenderViewPortType) {
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        let gameViewController = storyboard.instantiateController(withIdentifier: "Content") as! GameViewController
        
        mtkViews[viewPortType] = (gameViewController.view as! MTKView)
        mtkViews[viewPortType]!.isPaused = true
        storyboards[viewPortType] = storyboard
        gameViewControllers[viewPortType] = gameViewController
        setRenderer(mtkView: mtkViews[viewPortType]!, viewPortType: viewPortType)
        renderers[viewPortType]!.updateRenderSettings(settings: viewPortSettings[viewPortType]!)
//            mtkViews[viewPortType]!.addSubview(counterView)
    }
    
    private static func setRenderer(mtkView: MTKView, viewPortType: RenderViewPortType) {
        var renderer: Renderer!
        
        switch viewPortType {
        case .VertexShader:
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
        
        renderers[viewPortType] = renderer!
        renderer!.updateScene(sceneType: sceneType)
        mtkView.delegate = renderer!
        renderer!.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
}
