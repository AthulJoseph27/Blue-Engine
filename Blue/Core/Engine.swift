import MetalKit

class Engine {
    public static var Device: MTLDevice!
    public static var CommandQueue: MTLCommandQueue!
    
    public static func Start(device: MTLDevice) {
        self.Device = device
        self.CommandQueue = device.makeCommandQueue()
        
        ShaderLibrary.initialize()
        VertexDescriptorLibrary.initialize()
        RenderPipelineDescriptorLibrary.initialize()
        RenderPipelineStateLibrary.initialize()
        MeshLibrary.initialize()
        SceneManager.initialize(.Sandbox)
        DepthStencilStateLibrary.initialize()
    }
    
}
