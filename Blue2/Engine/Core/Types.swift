import simd

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

extension Float: sizeable {}
extension SIMD3: sizeable {}
extension SIMD4: sizeable {}

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

struct SceneConstants: sizeable {
    var projectionMatrix = matrix_identity_float4x4
    
}

struct TriangleOut: sizeable {
    // triangle to sent out to GPU
    var A: uint
    var B: uint
    var C: uint
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
}

struct TriangleIn: sizeable {
    // triangle when reading from 3D files
    var vertices: [SIMD3<Float>]
    var normal: SIMD3<Float>
    var color: SIMD4<Float>
    var uvCoordinates: [SIMD2<Float>]
}

struct ModelData: sizeable {
    var textureFile: String
    var triangles: [TriangleIn]
}

struct Focus {
    var position: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
    var forward: SIMD3<Float>
}

struct AreaLight {
    var position: SIMD3<Float>
    var forward: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
    var color: SIMD3<Float>
}

struct Uniforms: sizeable
{
    var width: uint
    var height: uint
    var triangleCount: uint
    var verticesCount: uint
    var skyBoxSize: SIMD2<Int32>
    var isSkyBoxSet: Bool
    var cameraPositionDelta: SIMD3<Float>
    var cameraRotation: SIMD3<Float>
}

struct RotationMatrix: sizeable {
    var rotationMatrix: matrix_float4x4
}
