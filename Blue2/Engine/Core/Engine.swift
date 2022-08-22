import MetalKit

class Engine {
    public static var device: MTLDevice!
    public static var commandQueue: MTLCommandQueue!
    public static var defaultLibrary: MTLLibrary!
    
    public static func start(device: MTLDevice) {
        self.device = device
        self.commandQueue = device.makeCommandQueue()
        self.defaultLibrary = device.makeDefaultLibrary()
        
        ComputePipelineDescriptorLibrary.initialize()
        ComputePipelineStateLibrary.initialize()
        MeshLibrary.initialize()
    }
}

