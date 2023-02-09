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
    
    func createBuffers() {}
    
    func drawSolids(renderEncoder: MTLRenderCommandEncoder) {
        var currentCamera = CameraManager.currentCamera!
        
        sceneConstants.viewMatrix = currentCamera.viewMatrix
        sceneConstants.projectionMatrix = currentCamera.projectionMatrix
        sceneConstants.cameraPosition = currentCamera.position
        renderEncoder.setVertexBytes(&sceneConstants, length: SceneConstants.stride, index: 1)
        
        currentCamera.deltaRotation = SIMD3<Float>(repeating: 0)
        currentCamera.deltaPosition = SIMD3<Float>(repeating: 0)
        
        renderEncoder.setDepthStencilState(DepthStencilLibrary.depthStencilState(.Less ))
        
        for solid in objects {
            renderEncoder.setVertexBuffer(solid.mesh.vertexBuffer, offset: 0, index: 0)
            var modelConstants = ModelConstants(modelMatrix: solid.modelMatrix)
            renderEncoder.setVertexBytes(&modelConstants, length: ModelConstants.stride, index: 2)
            for indexBuffer in solid.mesh.indexBuffers {
                let indexCount = indexBuffer.length / UInt32.stride
                renderEncoder.drawIndexedPrimitives(type: .triangle, indexCount: indexCount, indexType: .uint32, indexBuffer: indexBuffer, indexBufferOffset: 0)
            }
        }
        
        renderEncoder.setFragmentSamplerState(sampler, index: 0)
    }
    
    func updateObjects(deltaTime: Float) {}
    
    func updateScene(deltaTime: Float) {
    }
    
}
