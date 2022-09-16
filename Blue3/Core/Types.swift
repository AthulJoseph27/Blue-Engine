import simd
import MetalPerformanceShaders

protocol sizeable {}
extension sizeable {
    static var size: Int{
        return MemoryLayout<Self>.size
    }
    
    static var stride: Int {
        return MemoryLayout<Self>.stride
    }
    
    static func size(_ count: Int)->Int {
        return MemoryLayout<Self>.size * count
    }
    
    static func stride(_ count: Int)->Int {
        return MemoryLayout<Self>.stride * count
    }
}

extension uint: sizeable {}
extension Float: sizeable {}
extension SIMD2: sizeable {}
extension SIMD3: sizeable {}
extension SIMD4: sizeable {}
extension MPSIntersectionDistancePrimitiveIndexCoordinates: sizeable {}

struct Vertex: sizeable{
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

struct VertexOut: sizeable{
    var index: uint
    var position: SIMD3<Float>
}

struct ModelConstants: sizeable {
    var modelMatrix = matrix_identity_float4x4
}

struct TriangleIn: sizeable {
    // triangle when reading from 3D files
    var vertices: [Int]
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
    var uvCoordinates: [SIMD2<Float>]
}

struct ModelData: sizeable {
    var textureFile: String
    var triangles: [TriangleIn]
}

struct AreaLight: sizeable {
    var position: SIMD3<Float>
    var forward: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
    var color: SIMD3<Float>
}

struct RotationMatrix: sizeable {
    var rotationMatrix: matrix_float4x4
}

struct CameraOut: sizeable {
    var position: SIMD3<Float>
    var forward: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
//    var rotationMatrix: matrix_float4x4
}

class Masks {
    public static let FACE_MASK_NONE: uint = 0
    public static let FACE_MASK_NEGATIVE_X: uint = (1 << 0)
    public static let FACE_MASK_POSITIVE_X: uint = (1 << 1)
    public static let FACE_MASK_NEGATIVE_Y: uint = (1 << 2)
    public static let FACE_MASK_POSITIVE_Y: uint = (1 << 3)
    public static let FACE_MASK_NEGATIVE_Z: uint = (1 << 4)
    public static let FACE_MASK_POSITIVE_Z: uint = (1 << 5)
    public static let FACE_MASK_ALL: uint = ((1 << 6) - 1)
    
    public static let TRIANGLE_MASK_GEOMETRY: uint = 1
    public static let TRIANGLE_MASK_LIGHT: uint = 2
}
