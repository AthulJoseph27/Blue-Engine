import MetalKit
import simd
import os

enum RendererTypes {
    case VertexShader
    case RayTracing
}

class RendererManager {
    private static var mtkView: MTKView!
    private static var display: ((Double) -> Void)!
    private static var renderer: Renderer!
    
    public static func initialize(view: MTKView, displayCounter: @escaping (Double) -> Void) {
        self.display = displayCounter
        self.mtkView = view
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
               }catch let error as NSError {
                   print("ERROR::CREATE::RAY_TRACING_RENERER__::\(error)")
               }
        }
        
        let newRenderer = renderer!
        mtkView.delegate = newRenderer
        newRenderer.mtkView(mtkView, drawableSizeWillChange: mtkView.drawableSize)
    }
}
