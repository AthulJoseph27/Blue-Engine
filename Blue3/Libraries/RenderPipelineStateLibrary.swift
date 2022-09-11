import MetalKit

enum RenderPipelineStateTypes {
    case RayTracing
}

class RenderPipelineStateLibrary {
    private static var renderPipelineStates: [RenderPipelineStateTypes : RenderPipelineState] = [:]
    
    public static func initialize() {
        createRenderPipelineState()
    }
    
    public static func createRenderPipelineState() {
        renderPipelineStates.updateValue(RayTracing_RenderPipelineState(), forKey: .RayTracing)
    }
    
    public static func addRenderPipelineState(_ renderPipeLineState: RenderPipelineState, renderPipelineStateType: RenderPipelineStateTypes) {
        renderPipelineStates.updateValue(renderPipeLineState, forKey: renderPipelineStateType)
    }
    
    public static func pipelineState(_ renderPipelineStateTypes: RenderPipelineStateTypes)->MTLRenderPipelineState {
        return renderPipelineStates[renderPipelineStateTypes]!.renderPipelineState
    }
}

protocol RenderPipelineState {
    var name: String { get }
    var renderPipelineState: MTLRenderPipelineState! { get }
}

public struct RayTracing_RenderPipelineState: RenderPipelineState {
    var name: String = "Ray Tracing Render Pipeline State"
    var renderPipelineState: MTLRenderPipelineState!
    
    init() {
        do{
            renderPipelineState = try Engine.device.makeRenderPipelineState(descriptor: RenderPipelineDescriptorLibrary.descriptor(.RayTracing))
        }catch let error as NSError{
            print("ERROR::CREATE::RENDER_PIPELINE_STATE::__\(name)__::\(error)")
        }
    }
}
