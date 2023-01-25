import MetalKit
import MetalPerformanceShaders

class DynamicScene: Scene {

    var heap = Heap()
    
    var renderOptions = RenderOptions()
    
    var cameraManager = CameraManager()
    
    var masks: [uint]         = []
    var materials: [Material] = []
    var textures: [Textures]  = []
    
    var objects: [Solid] = []
    
    var vertexBuffer:        MTLBuffer!
    var indexBuffer:         MTLBuffer!
    var customIndexBuffer:   MTLBuffer!
    var textureBuffer:       MTLBuffer!
    var materialBuffer:      MTLBuffer!
    var verticesCountBuffer: MTLBuffer!
    var indiciesCountBuffer: MTLBuffer!
    var maskBuffer:          MTLBuffer!
    var transformBuffer:     MTLBuffer!
    var uniformBuffer:       MTLBuffer!
    
    var skyBox: MTLTexture!
    
    var instanceAccelerationStructures: [MPSInstanceAccelerationStructure]!
    
    var instanceBuffer: MTLBuffer!
    
    var frameIndex: uint = 0
    var uniformBufferOffset: Int!
    var uniformBufferIndex: Int = 0
    
    var indexWrapperPipeline: MTLComputePipelineState!
    
    init() {
        indexWrapperPipeline = ComputePipelineStateLibrary.pipelineState(.IndexWrapper).computePipelineState
        skyBox = Skyboxibrary.skybox(.Jungle)
        initialize()
        buildScene()
    }
    
    func initialize() {
    }
    
    func buildScene() {}
    
    func getAccelerationStructure()->MPSAccelerationStructure {
        return instanceAccelerationStructures[Int(frameIndex) % renderOptions.maxFramesInFlight]
    }
    
    func addSolid(solid: Solid) {
        objects.append(solid)
        
        for i in 0..<solid.mesh.submeshCount {
            materials.append(solid.mesh.materials[i])
            textures.append(Textures(baseColor: solid.mesh.baseColorTextures[i], normalMap: solid.mesh.normalMapTextures[i], metallic: solid.mesh.metallicMapTextures[i], roughness: solid.mesh.roughnessMapTextures[i]))
            
            if solid.lightSource {
                masks.append(uint(TRIANGLE_MASK_LIGHT))
            } else {
                masks.append(uint(TRIANGLE_MASK_GEOMETRY))
            }
        }
    }
    
    func check() {
        let vertexPointer = customIndexBuffer.contents().assumingMemoryBound(to: VertexIndex.self)
        let vertexCount = customIndexBuffer.length / MemoryLayout<VertexIndex>.stride

//            Iterate through the vertex and index data
           for i in 0..<vertexCount {
               let vertex = vertexPointer[i]
               print("Vertex \(i+1) :")
               print("\t submeshId: (\(vertex.submeshId))")
               print("\t index: (\(vertex.index))")
           }
    }
    
    func postBuildScene() {
        createBuffers()
//        check()
        createAccelerationStructures()
        heap.initialize(textures: &textures, sourceTextureBuffer: &textureBuffer)
    }
    
    func createBuffers() {
        // Vertex Buffers
        let commandBuffer = Engine.device.makeCommandQueue()?.makeCommandBuffer()
        commandBuffer?.label = "Buffer merge Command Buffer"
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.label = "Buffer merge Blit Encoder";
        
        var vertexBuffers:       [MTLBuffer] = []
        var indexBuffers:        [MTLBuffer] = []
        var wrappedIndexBuffers: [MTLBuffer] = []
        
        var transforms: [matrix_float4x4] = []
        var instances:  [UInt32] = []
        var indiciesCount: [UInt32] = [0]
        var verticesCount: [UInt32]  = []
        var instanceId = 0
        
        var submeshId: UInt32 = 0
        var indexOffset = 0
        
        var cummulativeVertexCount: UInt32 = 0
        
        for i in 0..<objects.count {
            let solid = objects[i]
            vertexBuffers.append(solid.mesh.vertexBuffer)

            indexBuffers.append(contentsOf: solid.mesh.indexBuffers)
            for j in 0..<solid.mesh.submeshCount {
                transforms.append(solid.modelMatrix)
                wrappedIndexBuffers.append(wrapIndexBuffer(indexBuffer: &solid.mesh.indexBuffers[j], keepOriginalIndex: true, indexOffset: UInt32(indexOffset), submeshId: submeshId))
                verticesCount.append(UInt32(cummulativeVertexCount))
                indiciesCount.append(indiciesCount.last! + UInt32(solid.mesh.indexBuffers[j].length / UInt32.stride))
                submeshId += 1
                indexOffset += (solid.mesh.indexBuffers[j].length / UInt32.stride)
                instances.append(uint(instanceId))
                instanceId += 1
            }
            
            cummulativeVertexCount += verticesCount.last! + UInt32(solid.mesh.vertexBuffer.length / VertexIn.stride)
        }
        
        self.vertexBuffer = mergeBuffers(buffers: vertexBuffers, blitEncoder: blitEncoder)
        self.indexBuffer = mergeBuffers(buffers: indexBuffers, blitEncoder: blitEncoder)
        self.customIndexBuffer = mergeBuffers(buffers: wrappedIndexBuffers, blitEncoder: blitEncoder)
        
        blitEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        let storageOptions: MTLResourceOptions
        storageOptions = .storageModeShared
        
        print(verticesCount)
        print(indiciesCount)
        // Other buffers
        verticesCountBuffer = Engine.device.makeBuffer(bytes: &verticesCount, length: UInt32.stride(verticesCount.count), options: storageOptions)
        indiciesCountBuffer = Engine.device.makeBuffer(bytes: &indiciesCount, length: UInt32.stride(indiciesCount.count), options: storageOptions)
        
        let uniformBufferSize = renderOptions.alignedUniformsSize * renderOptions.maxFramesInFlight
        self.uniformBuffer = Engine.device.makeBuffer(length: uniformBufferSize, options: storageOptions)
        self.instanceBuffer = Engine.device.makeBuffer(bytes: &instances, length: uint.stride(instances.count), options: storageOptions)
        self.transformBuffer = Engine.device.makeBuffer(bytes: &transforms, length: matrix_float4x4.stride(transforms.count), options: storageOptions)
        self.materialBuffer = Engine.device.makeBuffer(bytes: &materials, length: Material.stride(materials.count), options: storageOptions)
        self.maskBuffer = Engine.device.makeBuffer(bytes: &masks, length: uint.stride(masks.count), options: storageOptions)
    }
    
    func createAccelerationStructures() {
        let group = MPSAccelerationStructureGroup(device: Engine.device)
        var acceleratedStructures: [MPSTriangleAccelerationStructure] = []
        
        var vertexBufferOffset = 0
        var indexBufferOffset = 0
        
        var instanceCount = 0
        
        for solid in objects {
            for i in 0..<solid.mesh.submeshCount {
                let triangleAccelerationStructure = MPSTriangleAccelerationStructure(group: group)
                
                triangleAccelerationStructure.vertexBuffer = vertexBuffer
                triangleAccelerationStructure.vertexBufferOffset = vertexBufferOffset
                triangleAccelerationStructure.vertexStride = VertexIn.stride
                triangleAccelerationStructure.indexBuffer = indexBuffer
                triangleAccelerationStructure.indexBufferOffset = indexBufferOffset
                triangleAccelerationStructure.triangleCount = solid.mesh.indexBuffers[i].length / (3 * Int32.stride)
                
                if solid.animated {
                    triangleAccelerationStructure.usage = .refit
                }
                
                triangleAccelerationStructure.rebuild()
                
                acceleratedStructures.append(triangleAccelerationStructure)
                indexBufferOffset += solid.mesh.indexBuffers[i].length
                instanceCount += 1
            }
            vertexBufferOffset += solid.mesh.vertexBuffer.length
        }
        
        instanceAccelerationStructures = []
        
        for _ in 0..<renderOptions.maxFramesInFlight {
            let instanceAcceleratedStructure = MPSInstanceAccelerationStructure(group: group)
            instanceAcceleratedStructure.accelerationStructures = acceleratedStructures

            instanceAcceleratedStructure.transformBuffer = transformBuffer
            instanceAcceleratedStructure.instanceBuffer = instanceBuffer
            instanceAcceleratedStructure.instanceCount = instanceCount
            instanceAcceleratedStructure.maskBuffer = maskBuffer
            instanceAcceleratedStructure.rebuild()
            
            instanceAccelerationStructures.append(instanceAcceleratedStructure)
        }
    }
    
    func updateScene(deltaTime: Float) {
        
    }
    
    func updateObjects(deltaTime: Float) {
        
    }
    
    func updateUniforms(size: CGSize) {

    }
    
}
