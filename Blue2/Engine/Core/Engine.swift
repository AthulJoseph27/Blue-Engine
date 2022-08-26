import MetalKit

class Engine {
    public static var device: MTLDevice!
    public static var commandQueue: MTLCommandQueue!
    public static var defaultLibrary: MTLLibrary!
    public static var textureLoader: MTKTextureLoader!
    
    public static func start(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.defaultLibrary = device.makeDefaultLibrary()
        self.textureLoader = MTKTextureLoader(device: device)
        
        ComputePipelineDescriptorLibrary.initialize()
        ComputePipelineStateLibrary.initialize()
        VertexDescriptorLibrary.initialize()
        MeshLibrary.initialize()
        Skyboxibrary.initialize()
    }
}

