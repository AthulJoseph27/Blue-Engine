import MetalKit
import simd
import os

enum RendererTypes {
    case VertexShader
    case RayTracing
}

class RendererManager {
    private static let counterView = NSLabel(frame: NSRect(x: 10, y: 10, width: 150, height: 50))
    private static var display = { (value: Double) -> Void in
        counterView.stringValue = String(format: "MRays/s: %.3f", value / 1_000_000)
    }
    private static var mtkView: MTKView!
    private static var renderer: Renderer?
    private static var renderMode: RenderMode = .display
    private static var postRenderingCallback: (() -> Void)?
    
    public static func initialize(view: MTKView) {
        self.mtkView = view
        counterView.stringValue = ""
        counterView.textColor = .white
        mtkView.addSubview(counterView)
    }
    
    public static func setRenderer(_ rendererType: RendererTypes) {
        switch rendererType {
        case .VertexShader:
            do{
                renderer = try BasicRenderer(withMetalKitView: mtkView, displayCounter: display)
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
        
        mtkView.delegate = renderer!
        renderer!.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
    
    public static func updateRenderer() {
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
    
    public static func setRenderMode(postRenderingCallback: @escaping () -> Void) {
        renderMode = .render
        renderer?.renderMode = .render
        renderer?.scene.cameraManager.lockCamera()
        renderer?.renderModeInitialize()
        self.postRenderingCallback = postRenderingCallback
    }
    
    public static func onRenderingComplete() {
        postRenderingCallback!()
        setDisplayMode()
    }
    
    public static func setDisplayMode() {
        renderMode = .display
        renderer?.renderMode = .display
        renderer?.scene.cameraManager.unlockCamera()
    }
}
