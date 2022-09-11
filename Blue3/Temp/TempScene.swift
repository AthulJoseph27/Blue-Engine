import simd
import MetalKit

class SceneTemp {
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
    
    var vertices: [SIMD3<Float>] = []
    var normals: [SIMD3<Float>] = []
    var colors: [SIMD3<Float>] = []
    var masks: [uint] = []
    
    func getTriangleNormal(v0: SIMD3<Float>, v1: SIMD3<Float>, S v2: SIMD3<Float>) -> SIMD3<Float> {
        let e1: SIMD3<Float> = normalize(v1 - v0);
        let e2: SIMD3<Float> = normalize(v2 - v0);
        
        return cross(e1, e2);
    }
    
    func createCubeFace(_ vertices: inout [SIMD3<Float>],_ normals: inout [SIMD3<Float>],_ colors: inout [SIMD3<Float>],_ cubeVertices: [SIMD3<Float>],_ color: SIMD3<Float>,_ i0: Int,_ i1: Int,_ i2: Int,_ i3: Int,_ inwardNormals: Bool,_ triangleMask: uint32) {
        
        let v0 = cubeVertices[i0];
        let v1 = cubeVertices[i1];
        let v2 = cubeVertices[i2];
        let v3 = cubeVertices[i3];
        
        var n0 = getTriangleNormal(v0: v0, v1: v1, S: v2);
        var n1 = getTriangleNormal(v0: v0, v1: v2, S: v3);
        
        if (inwardNormals) {
            n0 = -n0;
            n1 = -n1;
        }
        
        vertices.append(v0);
        vertices.append(v1);
        vertices.append(v2);
        vertices.append(v0);
        vertices.append(v2);
        vertices.append(v3);
        
        for _ in 0..<3 {
            normals.append(n0);
        }
        
        for _ in 0..<3 {
            normals.append(n1);
        }
        
        for _ in 0..<6 {
            colors.append(color);
        }
        
        for _ in 0..<2 {
            masks.append(triangleMask);
        }
    }
    
    func createCube(faceMask: uint32, color: SIMD3<Float>, transform: matrix_float4x4, inwardNormals: Bool, triangleMask: uint32) {
        
        var cubeVertices = [
            SIMD3<Float>(-0.5, -0.5, -0.5),
            SIMD3<Float>( 0.5, -0.5, -0.5),
            SIMD3<Float>(-0.5,  0.5, -0.5),
            SIMD3<Float>( 0.5,  0.5, -0.5),
            SIMD3<Float>(-0.5, -0.5,  0.5),
            SIMD3<Float>( 0.5, -0.5,  0.5),
            SIMD3<Float>(-0.5,  0.5,  0.5),
            SIMD3<Float>( 0.5,  0.5,  0.5),
        ]
        
        for i in 0..<8 {
            let vertex = cubeVertices[i];
            
            var transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0)
            transformedVertex = transform * transformedVertex;
            
            cubeVertices[i] = SIMD3<Float>(transformedVertex.x, transformedVertex.y, transformedVertex.z);
        }
        
        if ((faceMask & SceneTemp.FACE_MASK_NEGATIVE_X) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, 0, 4, 6, 2, inwardNormals, triangleMask)
        }
        
        if ((faceMask & SceneTemp.FACE_MASK_POSITIVE_X) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, 1, 3, 7, 5, inwardNormals, triangleMask)
        }
        
        if ((faceMask & SceneTemp.FACE_MASK_NEGATIVE_Y) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, 0, 1, 5, 4, inwardNormals, triangleMask)
        }
        
        if ((faceMask & SceneTemp.FACE_MASK_POSITIVE_Y) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, 2, 6, 7, 3, inwardNormals, triangleMask)
        }
        
        if ((faceMask & SceneTemp.FACE_MASK_NEGATIVE_Z) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, 0, 2, 3, 1, inwardNormals, triangleMask)
        }
        
        if ((faceMask & SceneTemp.FACE_MASK_POSITIVE_Z) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, 4, 5, 7, 6, inwardNormals, triangleMask)
        }
    }
}

