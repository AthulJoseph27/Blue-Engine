import MetalKit

enum RenderPipelineDescriptorTypes {
    case RayTracing
}

class RenderPipelineDescriptorLibrary {
    private static var renderPipelineDescriptors: [RenderPipelineDescriptorTypes : RenderPipelineDescriptor] = [:]
    
    public static func initialize() {
        createRenderPipelineDescriptor()
    }
    
    public static func createRenderPipelineDescriptor() {
        renderPipelineDescriptors.updateValue(RayTracing_RenderPipelineDescriptor(), forKey: .RayTracing)
    }
    
    public static func addRenderPipelineDescriptor(_ renderPipelineDescriptor: RenderPipelineDescriptor, renderPipelineType: RenderPipelineDescriptorTypes) {
        renderPipelineDescriptors.updateValue(renderPipelineDescriptor, forKey: renderPipelineType)
    }
    
    public static func descriptor(_ renderPipelineDescriptorTypes: RenderPipelineDescriptorTypes)->MTLRenderPipelineDescriptor {
        return renderPipelineDescriptors[renderPipelineDescriptorTypes]!.renderPipelineDescriptor
    }
}

protocol RenderPipelineDescriptor {
    var name: String { get }
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor! { get }
}

public struct RayTracing_RenderPipelineDescriptor: RenderPipelineDescriptor {
    var name: String = "RayTracing Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    
    init() {
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat
        renderPipelineDescriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "copyVertex")
        renderPipelineDescriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "copyFragment")
    }
}



