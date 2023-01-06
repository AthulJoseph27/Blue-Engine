import MetalKit
import MetalPerformanceShaders
import simd
import os

class BasicRenderer: Renderer {
    
    var vertexBuffer: MTLBuffer!
    var modelConstantsBuffer: MTLBuffer!
    var lightSourceBuffer: MTLBuffer!
//    var textureBuffer: MTLBuffer!
    var materialBuffer: MTLBuffer!
    var sourceTextures: MTLBuffer!
    var texture: MTLTexture!
    
    var heap: Heap!
    
    var renderPipeline: MTLRenderPipelineState!
    
    var sceneConstants: SceneConstants!
    
    override func initialize() {
        sceneConstants = SceneConstants()
        createPipelines()
        createScene()
        createBuffers()
        heap = Heap()
        heap.initialize(scene: scene, sourceTextureBuffer: &sourceTextures)
    }
    
    private func createPipelines() {
        renderPipeline = RenderPipelineStateLibrary.pipelineState(.Basic)
    }
    
    private func createScene() {
        SceneManager.setScene(.Sandbox, view.drawableSize)
        scene = SceneManager.currentScene
    }
    
    private func createBuffers() {
        var vertices: [VertexOut] = []
        
        for i in 0..<scene.vertices.count {
            vertices.append(VertexOut(position: scene.vertices[i], color: scene.colors[i], uvCoordinate: scene.uvCoordinates[i], textureId: scene.textureIds[i], materialId: scene.materialIds[i],
                normal: scene.normals[i]))
        }
        
        let storageOptions: MTLResourceOptions

        #if arch(x86_64)
        storageOptions = .storageModeManaged
        #else // iOS, tvOS
        storageOptions = .storageModeShared
        #endif

        self.vertexBuffer = device.makeBuffer(bytes: &vertices, length: VertexOut.stride(vertices.count), options: storageOptions)
        
        var modelConstants: [ModelConstants] = []
        for i in 0..<scene.modelConstants.count {
            modelConstants.append(scene.modelConstants[i])
        }
        
        self.modelConstantsBuffer = device.makeBuffer(bytes: &modelConstants, length: ModelConstants.stride(modelConstants.count), options: storageOptions)
        
        
//        var textures: [PrimitiveData] = []
        var materials: [Material] = scene.materials
        
//        for tex in scene.textures {
//            textures.append(PrimitiveData(texture: tex))
//        }
        
//        self.textureBuffer = device.makeBuffer(bytes: &textures, length: PrimitiveData.stride(textures.count), options: storageOptions)
        
        self.materialBuffer = device.makeBuffer(bytes: &materials, length: Material.stride(materials.count), options: storageOptions)
        
        
        var lightSources: [LightData] = []
        
        for light in scene.lightSources {
            lightSources.append(light.lightData)
        }
        
        self.lightSourceBuffer = device.makeBuffer(bytes: &lightSources, length: LightData.stride(lightSources.count), options: storageOptions)
        
        #if arch(x86_64)
        if storageOptions.contains(.storageModeManaged) {
            vertexBuffer.didModifyRange(0..<vertexBuffer.length)
//            textureBuffer.didModifyRange(0..<textureBuffer.length)
            materialBuffer.didModifyRange(0..<materialBuffer.length)
            lightSourceBuffer.didModifyRange(0..<lightSourceBuffer.length)
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
        sceneConstants.cameraPosition = currentCamera.position
        
        var modelConstants: [ModelConstants] = []
        for i in 0..<scene.modelConstants.count {
            modelConstants.append(scene.modelConstants[i])
        }
        
        self.modelConstantsBuffer = device.makeBuffer(bytes: &modelConstants, length: ModelConstants.stride(modelConstants.count))
        
        commandEncoder!.setDepthStencilState(DepthStencilLibrary.depthStencilState(.Less ))
        commandEncoder!.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder!.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        commandEncoder!.setVertexBuffer(modelConstantsBuffer, offset: 0, index: 2)
        
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
        let sampler = device.makeSamplerState(descriptor: sampleDescriptor)
        
        commandEncoder!.useHeap(heap.heap, stages: MTLRenderStages.fragment)
        commandEncoder!.setFragmentSamplerState(sampler, index: 0)
        commandEncoder!.setFragmentBuffer(materialBuffer, offset: 0, index: 0)
        commandEncoder!.setFragmentBuffer(sourceTextures, offset: 0, index: 1)
        commandEncoder!.setFragmentBuffer(lightSourceBuffer, offset: 0, index: 2)
        var lightSourcesCount = uint(scene.lightSources.count)
        commandEncoder!.setFragmentBytes(&lightSourcesCount, length: uint.size, index: 3)
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
