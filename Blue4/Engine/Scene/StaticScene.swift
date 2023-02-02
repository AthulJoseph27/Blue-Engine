import MetalKit
import MetalPerformanceShaders

class StaticScene: GameScene {

    var heap = Heap()
    
    var renderOptions = RayTracingRenderOptions()
    
    var cameraManager = CameraManager()
    
    var masks: [UInt32]         = []
    var rayMasks: [UInt32]    = []
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
    var rayMaskBuffer:       MTLBuffer!
    var transformBuffer:     MTLBuffer!
    var uniformBuffer:       MTLBuffer!
    
    var skyBox: MTLTexture!
    
    var accelerationStructure:      MPSTriangleAccelerationStructure!
    var transformPipeline:          MTLComputePipelineState!
    var indexWrapperPipeline:       MTLComputePipelineState!
    
    var frameIndex: uint = 0
    var uniformBufferOffset: Int!
    var uniformBufferIndex: Int = 0
    
    init() {
        skyBox = Skyboxibrary.skybox(.Jungle)
        transformPipeline = ComputePipelineStateLibrary.pipelineState(.Transform).computePipelineState
        indexWrapperPipeline = ComputePipelineStateLibrary.pipelineState(.IndexGenerator).computePipelineState
        initialize()
        buildScene()
    }
    
    func initialize() {}
    
    func buildScene() {}
    
    func updateObjects(deltaTime: Float) {}
    
    func getAccelerationStructure()->MPSAccelerationStructure {
        return accelerationStructure
    }
    
    func addSolid(solid: Solid) {
        objects.append(solid)
        
        for i in 0..<solid.mesh.submeshCount {
            materials.append(solid.mesh.materials[i])
            textures.append(Textures(baseColor: solid.mesh.baseColorTextures[i], normalMap: solid.mesh.normalMapTextures[i], metallic: solid.mesh.metallicMapTextures[i], roughness: solid.mesh.roughnessMapTextures[i]))
            
            for _ in 0..<solid.mesh.indexBuffers[i].length / (3 * UInt32.stride) {
                if solid.lightSource {
                    rayMasks.append(UInt32(TRIANGLE_MASK_LIGHT))
                } else {
                    rayMasks.append(UInt32(TRIANGLE_MASK_GEOMETRY))
                }
            }
            
            if solid.lightSource {
                masks.append(UInt32(TRIANGLE_MASK_LIGHT))
            } else {
                masks.append(UInt32(TRIANGLE_MASK_GEOMETRY))
            }
        }
    }
    
    func check() {
        let vertexBufferPointer = vertexBuffer.contents()
        let vertexBufferData = vertexBufferPointer.bindMemory(to: VertexIn.self, capacity: vertexBuffer.length)
        for i in 0..<vertexBuffer.length/MemoryLayout<VertexIn>.stride {
            print("Vertex attribute position: \(vertexBufferData[i].position)")
        }

        let indexBufferPointer = indexBuffer.contents()
        let indexBufferData = indexBufferPointer.bindMemory(to: UInt32.self, capacity: indexBuffer.length)
        for i in 0..<indexBuffer.length/MemoryLayout<UInt32>.stride {
                print("Index \(i): \(indexBufferData[i])")
            }
    }
    
    func postBuildScene() {
        createBuffers()
        createAcceleratedStructure()
        heap.initialize(textures: &textures, sourceTextureBuffer: &textureBuffer)
    }
    
    func transformSolid(vertexBuffer: inout MTLBuffer, indexBuffer: inout MTLBuffer, transform: matrix_float4x4)->MTLBuffer {
        
        var vertexCount = indexBuffer.length / UInt32.stride
        var transformMatrix = transform
        let transformedVertexBuffer = Engine.device.makeBuffer(length: VertexIn.stride(vertexCount), options: .storageModeShared)
        
        let commandBuffer = Engine.commandQueue.makeCommandBuffer()!
        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        computeEncoder.setBuffer(vertexBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(indexBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(transformedVertexBuffer, offset: 0, index: 2)
        computeEncoder.setBytes(&transformMatrix, length: matrix_float4x4.stride, index: 3)
        
        computeEncoder.setBytes(&vertexCount, length: uint.size, index: 4)
        
        var w = transformPipeline.threadExecutionWidth
        computeEncoder.setBytes(&w, length: uint.size, index: 5)
        
        computeEncoder.setComputePipelineState(transformPipeline)
        
        let threadsPerThreadgroup = MTLSizeMake(w, 1, 1)
        let threadsPerGrid = MTLSizeMake(vertexCount, 1, 1)
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        
        computeEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return transformedVertexBuffer!
    }
    
    func createBuffers() {
        // Vertex Buffers
        let commandBuffer = Engine.device.makeCommandQueue()?.makeCommandBuffer()
        commandBuffer?.label = "Buffer merge Command Buffer"
        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.label = "Buffer merge Blit Encoder";
        
        var indexBuffers:        [MTLBuffer] = []
        var wrappedIndexBuffers: [MTLBuffer] = []
        var transformedBuffers:  [MTLBuffer] = []
        
        var submeshId: UInt32 = 0
        var indexOffset = 0
        
        for i in 0..<objects.count {
            let solid = objects[i]
            indexBuffers.append(contentsOf: solid.mesh.indexBuffers)
            for j in 0..<solid.mesh.submeshCount {
                transformedBuffers.append(transformSolid(vertexBuffer: &solid.mesh.vertexBuffer, indexBuffer: &solid.mesh.indexBuffers[j], transform: solid.modelMatrix))
                wrappedIndexBuffers.append(wrapIndexBuffer(indexBuffer: &solid.mesh.indexBuffers[j], indexOffset: UInt32(indexOffset), submeshId: submeshId))
                submeshId += 1
                indexOffset += (solid.mesh.indexBuffers[j].length / UInt32.stride)
            }
        }
        
        self.vertexBuffer = mergeBuffers(buffers: transformedBuffers, blitEncoder: blitEncoder)
        self.customIndexBuffer = mergeBuffers(buffers: wrappedIndexBuffers, blitEncoder: blitEncoder)
        
        blitEncoder?.endEncoding()
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        
        let storageOptions: MTLResourceOptions
        storageOptions = .storageModeShared
        
        let vertexCount = vertexBuffer.length / VertexIn.stride
        var indicies: [uint] = []
        for i in 0..<vertexCount {
            indicies.append(uint(i))
        }
        self.indexBuffer = Engine.device.makeBuffer(bytes: &indicies, length: uint.stride(indicies.count), options: storageOptions)
        
        // Other buffers
        var verticesCount = [0]
        verticesCountBuffer = Engine.device.makeBuffer(bytes: &verticesCount, length: uint.stride(1), options: storageOptions)
        var indiciesCount = [0]
        indiciesCountBuffer = Engine.device.makeBuffer(bytes: &indiciesCount, length: uint.stride(1), options: storageOptions)
        
        let uniformBufferSize = renderOptions.alignedUniformsSize * renderOptions.maxFramesInFlight
        self.uniformBuffer = Engine.device.makeBuffer(length: uniformBufferSize, options: storageOptions)
        self.materialBuffer = Engine.device.makeBuffer(bytes: &materials, length: Material.stride(materials.count), options: storageOptions)
        self.maskBuffer = Engine.device.makeBuffer(bytes: &masks, length: UInt32.stride(masks.count), options: storageOptions)
        self.rayMaskBuffer = Engine.device.makeBuffer(bytes: &rayMasks, length: UInt32.stride(rayMasks.count), options: storageOptions)
    }
    
    func createAcceleratedStructure() {
        accelerationStructure = MPSTriangleAccelerationStructure(device: Engine.device)
        accelerationStructure.vertexBuffer = vertexBuffer
        accelerationStructure.vertexStride = VertexIn.stride
        accelerationStructure.indexBuffer = indexBuffer
        accelerationStructure.maskBuffer = rayMaskBuffer
        accelerationStructure.triangleCount = indexBuffer.length / (3 * UInt32.stride)
        accelerationStructure.rebuild()
    }
}
