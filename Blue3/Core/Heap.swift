import MetalKit

class Heap {
    var heap: MTLHeap!
    
    func initialize(scene: Scene!, sourceTextureBuffer: inout MTLBuffer!) {
        createHeap(scene)
        moveResourcesToHeap(scene)
        updateHeap(scene: scene, sourceTextures: &sourceTextureBuffer)
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
    
    private func createHeap(_ scene: Scene!){
        
        let heapDescriptor = MTLHeapDescriptor()
        heapDescriptor.storageMode = .private
        heapDescriptor.size = 0
        
        for i in 0..<scene.textures.count{
            
            let texture = scene.textures[i]
            
            let textureDescriptor = newDescriptorFromTexture(texture: texture, storageMode: heapDescriptor.storageMode)
            
            var sizeAndAlign = Engine.device.heapTextureSizeAndAlign(descriptor: textureDescriptor)
            
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align
            
            heapDescriptor.size += sizeAndAlign.size
            
        }
        
        // Create heap large enough to hold all resources
        heap = Engine.device.makeHeap(descriptor: heapDescriptor)
        heap.label = "Texture heap"
        
    }
    
    private func moveResourcesToHeap(_ scene: Scene!){

        let commandBuffer = Engine.device.makeCommandQueue()?.makeCommandBuffer()
        commandBuffer?.label = "Heap Upload Command Buffer"

        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.label = "Heap Transfer Blit Encoder";
        
        for i in 0..<scene.textures.count{
            
            let texture = scene.textures[i]
            
            if texture == nil {
                continue
            }
            
            let textureDescriptor = newDescriptorFromTexture(texture: texture, storageMode: heap.storageMode)
//            print(textureDescriptor)
//            print(heap)
            let heapTexture = heap.makeTexture(descriptor: textureDescriptor)

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
    
    private func updateHeap(scene: Scene!, sourceTextures: inout MTLBuffer!){
        
        let fragmentFunction = RenderPipelineDescriptorLibrary.descriptor(.Basic).fragmentFunction

        let argumentEncoder = fragmentFunction?.makeArgumentEncoder(bufferIndex: 1)

        let textureArgumentSize = argumentEncoder?.encodedLength ?? 0
        
        let textureArgumentArrayLength = textureArgumentSize * scene.textures.count

        sourceTextures = Engine.device.makeBuffer(length: textureArgumentArrayLength)

        sourceTextures?.label = "Texture List"

        for i in 0..<scene.textures.count {
            let argumentBufferOffset = i * textureArgumentSize

            argumentEncoder?.setArgumentBuffer(sourceTextures, offset: argumentBufferOffset)

            argumentEncoder?.setTexture(scene.textures[i], index: 0)
        }
    }
    
    
}