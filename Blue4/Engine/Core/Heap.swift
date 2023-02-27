import MetalKit

class Heap {
    var heap: MTLHeap!
    
    func initialize(textures: inout [Textures], sourceTextureBuffer: inout MTLBuffer!) {
        createHeap(textures)
        moveResourcesToHeap(&textures)
        updateHeap(textures: textures, sourceTextures: &sourceTextureBuffer)
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
        textureDescriptor.usage = .shaderRead
        
        return textureDescriptor
    }
    
    private func createHeap(_ textures: [Textures]){
        
        let heapDescriptor = MTLHeapDescriptor()
        heapDescriptor.storageMode = .private
        heapDescriptor.size = 0
        
        for texture in textures{

            var textureDescriptor = newDescriptorFromTexture(texture: texture.baseColor, storageMode: heapDescriptor.storageMode)
            var sizeAndAlign = Engine.device.heapTextureSizeAndAlign(descriptor: textureDescriptor)
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align
            heapDescriptor.size += sizeAndAlign.size
            
            textureDescriptor = newDescriptorFromTexture(texture: texture.normalMap, storageMode: heapDescriptor.storageMode)
            sizeAndAlign = Engine.device.heapTextureSizeAndAlign(descriptor: textureDescriptor)
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align
            heapDescriptor.size += sizeAndAlign.size
            
            textureDescriptor = newDescriptorFromTexture(texture: texture.metallic, storageMode: heapDescriptor.storageMode)
            sizeAndAlign = Engine.device.heapTextureSizeAndAlign(descriptor: textureDescriptor)
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align
            heapDescriptor.size += sizeAndAlign.size
            
            textureDescriptor = newDescriptorFromTexture(texture: texture.roughness, storageMode: heapDescriptor.storageMode)
            sizeAndAlign = Engine.device.heapTextureSizeAndAlign(descriptor: textureDescriptor)
            sizeAndAlign.size += (sizeAndAlign.size & (sizeAndAlign.align - 1)) + sizeAndAlign.align
            heapDescriptor.size += sizeAndAlign.size
        }
        
        // Create heap large enough to hold all resources
        heap = Engine.device.makeHeap(descriptor: heapDescriptor)
        heap.label = "Texture heap"
        
    }
    
    private func moveTextureToHeap(texture: MTLTexture?, blitEncoder: MTLBlitCommandEncoder?)->MTLTexture? {
        if texture == nil {
            return nil
        }
        
        let textureDescriptor = newDescriptorFromTexture(texture: texture, storageMode: heap.storageMode)

        let heapTexture = heap.makeTexture(descriptor: textureDescriptor)
        
        if heapTexture == nil {
            print("Most probably heap overflow ⚠️⚠️⚠️")
            return nil
        }

        heapTexture?.label = texture?.label;

        var region = MTLRegionMake2D(0, 0, texture?.width ?? 0, texture?.height ?? 0);

        for level in 0..<(texture?.mipmapLevelCount ?? 0){

            for slice in 0..<texture!.arrayLength{
                
                blitEncoder?.copy(from: texture!, sourceSlice: slice, sourceLevel: level, sourceOrigin: region.origin, sourceSize: region.size, to: heapTexture!, destinationSlice: slice, destinationLevel: level, destinationOrigin: region.origin)
            }

            region.size.width /= 2
            region.size.height /= 2
            if region.size.width == 0 {
                region.size.width = 1
            }
            if region.size.height == 0 {
                region.size.height = 1
            }

            blitEncoder?.popDebugGroup()
        }

        blitEncoder?.popDebugGroup()
        
        return heapTexture
    }
    
    private func moveResourcesToHeap(_ textures: inout [Textures]){

        let commandBuffer = Engine.device.makeCommandQueue()?.makeCommandBuffer()
        commandBuffer?.label = "Heap Upload Command Buffer"

        let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
        blitEncoder?.label = "Heap Transfer Blit Encoder";
        
        for i in 0..<textures.count{
            
            var texture = textures[i].baseColor
            textures[i].baseColor = moveTextureToHeap(texture: texture, blitEncoder: blitEncoder)
            
            texture = textures[i].normalMap
            textures[i].normalMap = moveTextureToHeap(texture: texture, blitEncoder: blitEncoder)
            
            texture = textures[i].metallic
            textures[i].metallic = moveTextureToHeap(texture: texture, blitEncoder: blitEncoder)
            
            texture = textures[i].roughness
            textures[i].roughness = moveTextureToHeap(texture: texture, blitEncoder: blitEncoder)
        }

        blitEncoder?.endEncoding()

        commandBuffer?.commit()
    }
    
    private func updateHeap(textures: [Textures], sourceTextures: inout MTLBuffer!){
        
        let fragmentFunction = RenderPipelineDescriptorLibrary.descriptor(.Basic).fragmentFunction
        let argumentEncoder = fragmentFunction?.makeArgumentEncoder(bufferIndex: 1)
        let textureArgumentSize = argumentEncoder?.encodedLength ?? 0
        let textureArgumentArrayLength = textureArgumentSize * textures.count

        sourceTextures = Engine.device.makeBuffer(length: textureArgumentArrayLength)
        sourceTextures?.label = "Texture List"
        
        for i in 0..<textures.count {
            let argumentBufferOffset = i * textureArgumentSize

            argumentEncoder?.setArgumentBuffer(sourceTextures, offset: argumentBufferOffset)

            argumentEncoder?.setTexture(textures[i].baseColor, index: 0)
            argumentEncoder?.setTexture(textures[i].normalMap, index: 1)
            argumentEncoder?.setTexture(textures[i].metallic,  index: 2)
            argumentEncoder?.setTexture(textures[i].roughness, index: 3)
        }
    }
    
    
}
