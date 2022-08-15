import MetalKit

enum RenderPipelineStateTypes {
    case Basic
    case Instanced
}

class RenderPipelineStateLibrary {
    private static var renderPipelineStates: [RenderPipelineStateTypes : RenderPipelineState] = [:]
    
    public static func initialize() {
        createRenderPipelineState()
    }
    
    public static func createRenderPipelineState() {
        renderPipelineStates.updateValue(Basic_RenderPipelineState(), forKey: .Basic)
        renderPipelineStates.updateValue(Instanced_RenderPipelineState(), forKey: .Instanced)
    }
    
    public static func pipelineState(_ renderPipelineStateTypes: RenderPipelineStateTypes)->MTLRenderPipelineState {
        return renderPipelineStates[renderPipelineStateTypes]!.renderPipelineState
    }
}

protocol RenderPipelineState {
    var name: String { get }
    var renderPipelineState: MTLRenderPipelineState! { get }
}

public struct Basic_RenderPipelineState: RenderPipelineState {
    var name: String = "Baisc Render Pipeline State"
    var renderPipelineState: MTLRenderPipelineState!
    
    init() {
        do{
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptorLibrary.descriptor(.Basic))
        }catch let error as NSError{
            print("ERROR::CREATE::RENDER_PIPELINE_STATE::__\(name)__::\(error)")
        }
    }
}

public struct Instanced_RenderPipelineState: RenderPipelineState {
    var name: String = "Instanced Render Pipeline State"
    var renderPipelineState: MTLRenderPipelineState!
    
    init() {
        do{
            renderPipelineState = try Engine.Device.makeRenderPipelineState(descriptor: RenderPipelineDescriptorLibrary.descriptor(.Instanced))
        }catch let error as NSError{
            print("ERROR::CREATE::RENDER_PIPELINE_STATE::__\(name)__::\(error)")
        }
    }
}
