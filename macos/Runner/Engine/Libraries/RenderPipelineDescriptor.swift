import MetalKit

enum RenderPipelineDescriptorTypes {
    case Basic
    case RayTracing
    case Rendering
    case DenoiserRasterizer
}

class RenderPipelineDescriptorLibrary {
    private static var renderPipelineDescriptors: [RenderPipelineDescriptorTypes : RenderPipelineDescriptor] = [:]
    
    public static func initialize() {
        createRenderPipelineDescriptor()
    }
    
    public static func createRenderPipelineDescriptor() {
        renderPipelineDescriptors.updateValue(Basic_RenderPipelineDescriptor(), forKey: .Basic)
        renderPipelineDescriptors.updateValue(RayTracing_RenderPipelineDescriptor(), forKey: .RayTracing)
        renderPipelineDescriptors.updateValue(OffScreen_RenderPipelineDescriptor(), forKey: .Rendering)
        renderPipelineDescriptors.updateValue(DenoiserRasterizer_RenderPipelineDescriptor(), forKey: .DenoiserRasterizer)
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

public struct Basic_RenderPipelineDescriptor: RenderPipelineDescriptor {
    var name: String = "Baisc Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    
    init() {
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = Preferences.MainDepthPixelFormat
        renderPipelineDescriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "basic_vertex_shader")
        renderPipelineDescriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "basic_fragment_shader")
        
        renderPipelineDescriptor.vertexDescriptor = VertexDescriptorLibrary.getDescriptor(.Basic)
    }
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

public struct OffScreen_RenderPipelineDescriptor: RenderPipelineDescriptor {
    var name: String = "OffScreen Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    
    init() {
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = Preferences.MainPixelFormat
        renderPipelineDescriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "copyVertex")
        renderPipelineDescriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "copyFragment")
    }
}

public struct DenoiserRasterizer_RenderPipelineDescriptor: RenderPipelineDescriptor {
    var name: String = "DenoiserRasterizer Render Pipeline Descriptor"
    var renderPipelineDescriptor: MTLRenderPipelineDescriptor!
    
    init() {
        renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.rasterSampleCount = 1
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        renderPipelineDescriptor.vertexFunction = Engine.defaultLibrary.makeFunction(name: "denoiserVertexPass")
        renderPipelineDescriptor.fragmentFunction = Engine.defaultLibrary.makeFunction(name: "denoiserFragmentPass")
        
        renderPipelineDescriptor.vertexDescriptor = VertexDescriptorLibrary.getDescriptor(.Basic)
        
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .rgba16Float
        renderPipelineDescriptor.colorAttachments[1].pixelFormat = .rgba16Float
        renderPipelineDescriptor.colorAttachments[2].pixelFormat = .rg16Float
        renderPipelineDescriptor.colorAttachments[3].pixelFormat = .rgba32Float
        renderPipelineDescriptor.colorAttachments[4].pixelFormat = .rgba32Float
    }
}
