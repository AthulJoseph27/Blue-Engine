import MetalKit
import MetalPerformanceShaders
import simd
import os

class BasicRenderer: Renderer {
    
    var vertexBuffer: MTLBuffer!
    var textureBuffer: MTLBuffer!
    var materialBuffer: MTLBuffer!
    var sourceTextures: MTLBuffer!
    var texture: MTLTexture!
    
    var heap: MTLHeap!
    
    var renderPipeline: MTLRenderPipelineState!
    
    var sceneConstants: SceneConstants!
    
    override func initialize() {
        sceneConstants = SceneConstants()
        createPipelines()
        createScene()
        createBuffers()
        createHeap()
        moveResourcesToHeap()
        updateHeap()
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
            vertices.append(VertexOut(position: scene.vertices[i], color: scene.colors[i], uvCoordinate: scene.uvCoordinates[i], textureId: scene.textureIds[i], materialId: scene.materialIds[i]))
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
        var materials: [Material] = scene.materials
        
        for tex in scene.textures {
            textures.append(PrimitiveData(texture: tex))
        }
        
        self.textureBuffer = device.makeBuffer(bytes: &textures, length: PrimitiveData.stride(textures.count), options: storageOptions)
        
        self.materialBuffer = device.makeBuffer(bytes: &materials, length: Material.stride(materials.count), options: storageOptions)
        
        #if arch(x86_64)
        if storageOptions.contains(.storageModeManaged) {
            vertexBuffer.didModifyRange(0..<vertexBuffer.length)
            textureBuffer.didModifyRange(0..<textureBuffer.length)
            materialBuffer.didModifyRange(0..<materialBuffer.length)
        }
        #endif
        
    }
    
    private func newDescriptorFromTexture(texture: MTLTexture? = nil, storageMode: MTLStorageMode)->MTLTextureDescriptor{
        if texture == nil {
            return MTLTextureDescriptor()
        }
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.pixelFormat = texture!.pixelFormat
        textureDescriptor.width = texture!.width
        textureDescriptor.height = texture!.height
        textureDescriptor.depth = texture!.depth
        textureDescriptor.sampleCount = texture!.sampleCount
        textureDescriptor.mipmapLevelCount = texture!.mipmapLevelCount
        textureDescriptor.arrayLength = texture!.arrayLength
        textureDescriptor.storageMode = storageMode
        
        return textureDescriptor
    }
    
    private func createHeap(){
        
        let heapDescriptor = MTLHeapDescriptor()
        heapDescriptor.storageMode = .private
        heapDescriptor.size = 0
        
        for i in 0..<scene.textures.count{
            
            let texture = scene.textures[i]
            
            let textureDescriptor = newDescriptorFromTexture(texture: texture, storageMode: heapDescriptor.storageMode)
            
            var sizeAndAlign = device.heapTextureSizeAndAlign(descriptor: textureDescriptor)
            
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align
            
            heapDescriptor.size += sizeAndAlign.size
            
        }
        
        // Create heap large enough to hold all resources
        heap = device.makeHeap(descriptor: heapDescriptor)
        heap.label = "Texture heap"
        
    }
    
    private func moveResourcesToHeap(){

        let commandBuffer = device.makeCommandQueue()?.makeCommandBuffer()
        commandBuffer?.label = "Heap Upload Command Buffer"

        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.label = "Heap Transfer Blit Encoder";

        for i in 0..<scene.textures.count{
            
            let texture = scene.textures[i]
            
            let textureDescriptor = newDescriptorFromTexture(texture: texture, storageMode: heap.storageMode)

            let heapTexture = heap.makeTexture(descriptor: textureDescriptor);

            heapTexture?.label = texture?.label;

//            [blitEncoder pushDebugGroup:[NSString stringWithFormat:@"%@ Blits", heapTexture.label]];

            var region = MTLRegionMake2D(0, 0, texture?.width ?? 0, texture?.height ?? 0);

            for level in 0..<(texture?.mipmapLevelCount ?? 0){
//                [blitEncoder pushDebugGroup:[NSString stringWithFormat:@"Level %lu Blit", level]];

                for slice in 0..<texture!.arrayLength{
                    
                    blitEncoder?.copy(from: texture!, sourceSlice: slice, sourceLevel: level, sourceOrigin: region.origin, sourceSize: region.size, to: heapTexture!, destinationSlice: slice, destinationLevel: level, destinationOrigin: region.origin)
                }

                region.size.width /= 2
                region.size.height /= 2
                if region.size.width == 0{
                    region.size.width = 1
                }
                if region.size.height == 0{
                    region.size.height = 1
                }

                blitEncoder?.popDebugGroup()
            }

            blitEncoder?.popDebugGroup()

            scene.textures[i] = heapTexture;
        }

        blitEncoder?.endEncoding()

        commandBuffer?.commit()
    }
    
    private func updateHeap(){
        
        let fragmentFunction = RenderPipelineDescriptorLibrary.descriptor(.Basic).fragmentFunction

        let argumentEncoder = fragmentFunction?.makeArgumentEncoder(bufferIndex: 1)

        let textureArgumentSize = argumentEncoder?.encodedLength ?? 0
        
        let textureArgumentArrayLength = textureArgumentSize * scene.textures.count

        sourceTextures = device.makeBuffer(length: textureArgumentArrayLength)

        sourceTextures?.label = "Texture List"

        for i in 0..<scene.textures.count {
            let argumentBufferOffset = i * textureArgumentSize

            argumentEncoder?.setArgumentBuffer(sourceTextures, offset: argumentBufferOffset)

            argumentEncoder?.setTexture(scene.textures[i], index: 0)

        }
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
        
        let sampleDescriptor = MTLSamplerDescriptor()
        sampleDescriptor.minFilter = .linear
        sampleDescriptor.magFilter = .linear
        
        let sampler = device.makeSamplerState(descriptor: sampleDescriptor)
        
        commandEncoder!.useHeap(heap, stages: MTLRenderStages.fragment)
        commandEncoder!.setFragmentSamplerState(sampler, index: 0)
        commandEncoder!.setFragmentBuffer(materialBuffer, offset: 0, index: 0)
        commandEncoder!.setFragmentBuffer(sourceTextures, offset: 0, index: 1)
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
