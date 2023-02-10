import MetalKit
import MetalPerformanceShaders

class PhongShadingScene: RenderableScene {

    var renderOptions: PSRenderOptions = PSRenderOptions()
    
    var heap = Heap()
    var textures:  [Textures] = []
    var materials: [Material] = []
    var objects: [Solid] = []
    
    
    var materialBuffer: MTLBuffer!
    var textureBuffer: MTLBuffer!
    
    var skyBox: MTLTexture!
    
    var frameIndex: uint = 0
    
    var sceneConstants = SceneConstants()
    
    var sampler: MTLSamplerState?
    
    init(scene: GameScene) {
        skyBox = Skyboxibrary.skybox(.Sky)
        createSampler()
        buildScene(scene: scene)
        createBuffers()
        heap.initialize(textures: &textures, sourceTextureBuffer: &textureBuffer)
    }
    
    func createSampler() {
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
        sampler = Engine.device.makeSamplerState(descriptor: sampleDescriptor)
    }
    
    func buildScene(scene: GameScene) {
        for solid in scene.solids {
            addSolid(solid: solid)
        }
    }
    
    func addSolid(solid: Solid) {
        for i in 0..<solid.mesh.submeshCount {
            materials.append(solid.mesh.materials[i])
            textures.append(Textures(baseColor: solid.mesh.baseColorTextures[i], normalMap: solid.mesh.normalMapTextures[i], metallic: solid.mesh.metallicMapTextures[i], roughness: solid.mesh.roughnessMapTextures[i]))
        }
        
        objects.append(solid)
    }
    
    func createBuffers() {
        let storageOptions: MTLResourceOptions
        storageOptions = .storageModeShared
        
        self.materialBuffer = Engine.device.makeBuffer(bytes: &materials, length: Material.stride(materials.count), options: storageOptions)
    }
    
    func drawSolids(renderEncoder: MTLRenderCommandEncoder) {
        var currentCamera = CameraManager.currentCamera!
//        currentCamera.deltaRotation *= -1
        
        sceneConstants.viewMatrix = currentCamera.viewMatrix
        sceneConstants.projectionMatrix = currentCamera.projectionMatrix
        sceneConstants.cameraPosition = currentCamera.position
        renderEncoder.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        currentCamera.deltaRotation = SIMD3<Float>(repeating: 0)
        currentCamera.deltaPosition = SIMD3<Float>(repeating: 0)
        
        renderEncoder.setDepthStencilState(DepthStencilLibrary.depthStencilState(.Less))
        
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
        
        renderEncoder.useHeap(heap.heap, stages: .fragment)
        renderEncoder.setFragmentBuffer(textureBuffer, offset: 0, index: 1)
        
        var textureId: UInt32 = 0
        
        for solid in objects {
            renderEncoder.setVertexBuffer(solid.mesh.vertexBuffer, offset: 0, index: 0)
            
            var modelConstants = ModelConstants(modelMatrix: solid.modelMatrix)
            renderEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            
            
            for i in 0..<solid.mesh.indexBuffers.count {
                
                let indexBuffer = solid.mesh.indexBuffers[i]
                let indexCount = indexBuffer.length / UInt32.stride
                
                renderEncoder.setFragmentBytes(&solid.mesh.materials[i], length: Material.stride, index: 0)
                
                renderEncoder.setFragmentBytes(&textureId, length: UInt32.stride, index: 2)
                
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
                
                textureId += 1
            }
        }

    }
    
    func updateObjects(deltaTime: Float) {}
    
    func updateScene(deltaTime: Float) {}
    
}
