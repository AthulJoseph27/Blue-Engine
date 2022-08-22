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

extension SIMD3: sizeable {}
extension SIMD4: sizeable {}

struct Vertex: sizeable{
    var position: SIMD3<Float>
    var color: SIMD4<Float>
}

struct ModelConstants: sizeable {
    var modelMatrix = matrix_identity_float4x4
}

struct SceneConstants: sizeable {
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    
}

struct TriangleOut: sizeable {
    var A: SIMD3<Float>
    var B: SIMD3<Float>
    var C: SIMD3<Float>
    var normals: SIMD3<Float>
    var color: SIMD4<Float>
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
    var frameIndex: uint
    var cameraPositionDelta: SIMD3<Float>
    var cameraRotation: SIMD3<Float>
}
