import MetalKit

enum VertexDescriptorTypes {
    case Basic
    case Read
}

class VertexDescriptorLibrary {
    private static var descriptors: [VertexDescriptorTypes: VertexDescriptor] = [:]
    
    public static func initialize() {
        descriptors.updateValue(Basic_VertexDescriptor(), forKey: .Basic)
        descriptors.updateValue(Read_VertexDescriptor(), forKey: .Read)
    }
    
    public static func getDescriptor(_ type: VertexDescriptorTypes)->MTLVertexDescriptor {
        return descriptors[type]!.vertexDescriptor
    }
}

protocol VertexDescriptor {
    var name: String { get }
    var vertexDescriptor: MTLVertexDescriptor! { get }
}

public struct Basic_VertexDescriptor: VertexDescriptor{
    var name: String = "Basic Vertex Descriptor"
    
    var vertexDescriptor: MTLVertexDescriptor!
    init(){
        vertexDescriptor = MTLVertexDescriptor()
        
        //Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        //Color
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = SIMD3<Float>.size
        
        //UV Coords
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = SIMD3<Float>.size + SIMD4<Float>.size
        
        //TextureId
        vertexDescriptor.attributes[3].format = .uint
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[3].offset = SIMD3<Float>.size + SIMD4<Float>.size + SIMD2<Float>.size
        
        vertexDescriptor.layouts[0].stride = Vertex.stride
    }
}

public struct Read_VertexDescriptor: VertexDescriptor{
    var name: String = "Read Vertex Descriptor"
    
    var vertexDescriptor: MTLVertexDescriptor!
    init(){
        vertexDescriptor = MTLVertexDescriptor()
        
        //Position
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        
        //UV Coords
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].offset = SIMD3<Float>.size
        
        //Normal
        vertexDescriptor.attributes[2].format = .float3
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].offset = SIMD3<Float>.size + SIMD3<Float>.size
        
        vertexDescriptor.layouts[0].stride = VertexIn.stride
    }
}
