import MetalKit
import MetalPerformanceShaders
import simd
import os

class BasicRenderer: Renderer {
    
    var vertexBuffer: MTLBuffer!
    var textureBuffer: MTLBuffer!
    var materialBuffer: MTLBuffer!
    var texture: MTLTexture!
    
    var renderPipeline: MTLRenderPipelineState!
    
    var sceneConstants: SceneConstants!
    
    override func initialize() {
        sceneConstants = SceneConstants()
        createPipelines()
        createScene()
        createBuffers()
    }
    
    private func createPipelines() {
        renderPipeline = RenderPipelineStateLibrary.pipelineState(.Basic)
    }
    
    private func createScene() {
        SceneManager.setScene(.Sandbox, view.drawableSize)
        scene = SceneManager.currentScene
    }
    
    private func loadTextureFromBundle() {
        var result: MTLTexture!
        
        if let url = Bundle.main.url(forResource: "SampleTexture", withExtension: "jpg") {
            let textureLoader = MTKTextureLoader(device: device)
            
            let options: [MTKTextureLoader.Option : Any] = [MTKTextureLoader.Option.origin : MTKTextureLoader.Origin.topLeft]
            
            do {
                result = try textureLoader.newTexture(URL: url, options: options)
            }catch _ as NSError {
                print("Error")
            }
        }else{
            print("Error")
        }
        
        texture = result
    }
    
    private func createBuffers() {
        var vertices: [VertexOut] = []
        
        for i in 0..<scene.vertices.count {
            vertices.append(VertexOut(position: scene.vertices[i], color: scene.colors[i], uvCoordinate: scene.uvCoordinates[i], textureId: scene.textureIds[i]))
        }
        
//        loadTextureFromBundle()
        
        let storageOptions: MTLResourceOptions

        #if arch(x86_64)
        storageOptions = .storageModeManaged
        #else // iOS, tvOS
        storageOptions = .storageModeShared
        #endif

        self.vertexBuffer = device.makeBuffer(bytes: &vertices, length: VertexOut.stride(vertices.count), options: storageOptions)
        
        var textures: [PrimitiveData] = []
        
        for tex in scene.textures {
            textures.append(PrimitiveData(texture: tex))
        }
        
//        self.textureBuffer = device.makeBuffer(bytes: &textures, length: PrimitiveData.stride(textures.count), options: storageOptions)
        
        #if arch(x86_64)
        if storageOptions.contains(.storageModeManaged) {
            vertexBuffer.didModifyRange(0..<vertexBuffer.length)
//            textureBuffer.didModifyRange(0..<textureBuffer.length)
//            materialBuffer.didModifyRange(0..<materialBuffer.length)
        }
        #endif
        
    }
    
    private func updateBuffers(_ commandEncoder: MTLRenderCommandEncoder?) {
        
        if commandEncoder == nil {
            return
        }
        
        let currentCamera = scene.cameraManager.currentCamera!
        
        sceneConstants.viewMatrix = currentCamera.viewMatrix
        sceneConstants.projectionMatrix = currentCamera.projectionMatrix
        
        commandEncoder!.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder!.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        var material = Material()
//        material.useMaterialColor = true
        material.useTextureColor = true
        material.color = SIMD4<Float>(1, 1, 1, 1)
        
        commandEncoder!.setFragmentBytes(&material, length: Material.stride, index: 1)
        
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
        let sampler = device.makeSamplerState(descriptor: sampleDescriptor)
        
        commandEncoder!.setFragmentSamplerState(sampler, index: 0)
        commandEncoder!.setFragmentBuffer(textureBuffer, offset: 0, index: 1)
    }
    
    override func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    override func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = Engine.commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(renderPipeline)

        SceneManager.tickScene(deltaTime: 1/Float(view.preferredFramesPerSecond))
        updateBuffers(renderEncoder)
        
        renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: scene.vertices.count)
        
        renderEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        
        
    }
}
