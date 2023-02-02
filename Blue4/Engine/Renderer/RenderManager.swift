import MetalKit
import simd
import os

class RendererManager {
    private static let counterView = NSLabel(frame: NSRect(x: 10, y: 10, width: 150, height: 50))
    private static var display = { (value: Double) -> Void in
        counterView.stringValue = String(format: "MRays/s: %.3f", value / 1_000_000)
    }
    private static var mtkView: MTKView!
    private static var sceneType: SceneType?
    private static var renderer: Renderer?
    private static var renderMode: RenderMode = .display
    private static var viewPortSettings: [RendererType : RenderingSettings] = [
        .RayTracing : RayTracingSettings(maxBounce: 1),
        .VertexShader : VertexShadingSettings()
    ]
//    private static var renderers: [RendererType : Renderer] = [:]
    private static var postRenderingCallback: (() -> Void)?
    
    public static func initialize(view: MTKView) {
        self.mtkView = view
        if sceneType == nil {
            sceneType = .StaticSandbox
        }
        SceneManager.initialize(sceneType: sceneType!, drawableSize: view.drawableSize)
        counterView.stringValue = ""
        counterView.textColor = .white
        mtkView.addSubview(counterView)
    }
    
    public static func setRenderer(_ rendererType: RendererType) {
        switch rendererType {
        case .VertexShader:
            do{
                renderer = try PhongRenderer(withMetalKitView: mtkView, displayCounter: display)
            }catch let error as NSError {
                print("ERROR::CREATE::VERTEX_RENERER__::\(error)")
            }
        case .RayTracing:
            do{
                renderer = try RayTracingRenderer(withMetalKitView: mtkView, displayCounter: display)
            } catch let error as NSError {
                print("ERROR::CREATE::RAY_TRACING_RENERER__::\(error)")
            }
        }
        
        if renderer == nil {
            return
        }
        
        renderer?.updateScene(sceneType: sceneType ?? .StaticSandbox)
        mtkView.delegate = renderer!
        renderer!.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    public static func updateRenderer() {
        renderer?.updateScene(sceneType: sceneType ?? .StaticSandbox)
        mtkView.delegate = renderer!
        renderer!.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    public static func currentRenderer()->Renderer? {
        return renderer
    }
    
    public static func pauseRenderingLoop() {
        mtkView.isPaused = true
    }
    
    public static func resumeRenderingLoop() {
        mtkView.isPaused = false
    }
    
    public static func getRenderedTexture()->MTLTexture? {
        return renderer?.renderedTexture
    }
    
    public static func currentRenderMode() -> RenderMode {
        return renderMode
    }
    
    public static func setRenderMode(settings: RenderingSettings, postRenderingCallback: @escaping () -> Void) {
        renderMode = .render
        renderer?.switchToRenderMode(settings: settings)
        self.postRenderingCallback = postRenderingCallback
    }
    
    public static func onRenderingComplete() {
        postRenderingCallback!()
        setDisplayMode(settings: viewPortSettings[getCurrentRendererType()]!)
    }
    
    public static func setDisplayMode(settings: RenderingSettings) {
        renderMode = .display
        renderer?.switchToDisplayMode(settings: settings)
    }
    
    public static func updateViewPortSettings(rendererType: RendererType, settings: RenderingSettings) {
        viewPortSettings[rendererType] = settings
        if getCurrentRendererType() == rendererType {
            renderer?.renderingSettings = settings
        }
    }
    
    public static func updateCurrentScene(scene: SceneType) {
        print("hello from update current scene \(scene)")
        sceneType = scene
        renderer?.updateScene(sceneType: sceneType ?? .StaticSandbox)
    }
    
    private static func getCurrentRendererType() -> RendererType {
        if renderer is RayTracingRenderer {
            return .RayTracing
        } else {
            return .VertexShader
        }
    }
}
