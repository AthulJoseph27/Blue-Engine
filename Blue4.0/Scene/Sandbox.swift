import MetalKit
import MetalPerformanceShaders

class Sandbox: StaticScene {
    var camera = DebugCamera()
    var totalTime:Float = 0
    
    init(drawableSize: CGSize) {
        super.init()
    }
    
    override func buildScene() {
        renderOptions.maxBounce = 3
        
        camera.position = SIMD3<Float>(0, 1, 3.38)
        addCamera(camera)
        
        var transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.5, 1.98, 0.5))
        
        createCube(faceMask: Masks.FACE_MASK_POSITIVE_Y, color: SIMD3<Float>([1, 1, 1]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_LIGHT))
        
//         Top, bottom, back
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(2, 2, 2))
        createCube(faceMask: Masks.FACE_MASK_NEGATIVE_Y | Masks.FACE_MASK_POSITIVE_Y | Masks.FACE_MASK_NEGATIVE_Z, color: SIMD3<Float>([0.725, 0.71, 0.68]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

        // Left wall
        createCube(faceMask: Masks.FACE_MASK_NEGATIVE_X, color: SIMD3<Float>([0.63, 0.065, 0.05]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

//        // Right wall
        createCube(faceMask: Masks.FACE_MASK_POSITIVE_X, color: SIMD3<Float>([0.14, 0.45, 0.091]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))
        
//         Short box
        let monkey = Solid(.Monkey)
        monkey.position = SIMD3<Float>(0.3275, 0.3, 0.3725)
        monkey.rotation = SIMD3<Float>(0, -0.3, 0)
        monkey.scale = SIMD3<Float>(0.3, 0.3, 0.3)
        monkey.setColor(SIMD4<Float>(0.2, 0.2, 0.8, 1.0))
        monkey.setRoughness(1.0)
        monkey.enableTexture(false)
        monkey.animated = true

        addSolid(solid: monkey)
        
//         Tall box
        let chest = Solid(.Chest)
        chest.position = SIMD3<Float>(-0.375, 0.5, -0.29)
        chest.rotation = SIMD3<Float>(0, 0.3, 0)
        chest.scale = SIMD3<Float>(0.008, 0.008, 0.008)
        addSolid(solid: chest)
        
    }
    
//    override func updateObjects(deltaTime: Float) {
//        totalTime += deltaTime
//
//        let transformsData = transformBuffer.contents()
//        var pointer = transformsData.bindMemory(to: matrix_float4x4.self, capacity: 1)
//
//        let instanceAccelerationStructure = (getAccelerationStructure() as! MPSInstanceAccelerationStructure)
//        for i in 0..<objects.count {
//            let solid = objects[i]
//            if i == (objects.count - 2) {
//                solid.position.y = 0.3 + sin(totalTime) / 10
//            }
//            for _ in 0..<solid.mesh.submeshCount {
//                if solid.animated {
//                    pointer.pointee = solid.modelMatrix
//                }
//                pointer = pointer.advanced(by: 1)
//            }
//        }
//
//        instanceAccelerationStructure.transformBuffer = transformBuffer
//        instanceAccelerationStructure.rebuild()
//    }
    
    func addTriangle(v0: SIMD3<Float>, v1: SIMD3<Float>, v2: SIMD3<Float>, n0: SIMD3<Float>, material: Material, triangleMaks: UInt32) {
        let solid = Solid(.None)
        
        solid.mesh.submeshCount = 1
        solid.mesh.baseColorTextures = [nil]
        solid.mesh.normalMapTextures = [nil]
        solid.mesh.metallicMapTextures = [nil]
        solid.mesh.roughnessMapTextures = [nil]
        
        if triangleMaks == TRIANGLE_MASK_LIGHT {
            solid.lightSource = true
        }
        
        var vertices: [VertexIn] = []
        vertices.append(VertexIn(position: v0, uvCoordinate: SIMD2<Float>(0, 1), normal: n0, tangent: SIMD3<Float>(repeating: 1), bitangent: SIMD3<Float>(repeating: 1)))
        vertices.append(VertexIn(position: v1, uvCoordinate: SIMD2<Float>(-1, -1), normal: n0, tangent: SIMD3<Float>(repeating: 1), bitangent: SIMD3<Float>(repeating: 1)))
        vertices.append(VertexIn(position: v2, uvCoordinate: SIMD2<Float>(1, -1), normal: n0, tangent: SIMD3<Float>(repeating: 1), bitangent: SIMD3<Float>(repeating: 1)))
        
        var indicies: [UInt32] = [0, 1, 2]
        
        solid.mesh.vertexBuffer = Engine.device.makeBuffer(bytes: &vertices, length: VertexIn.stride(vertices.count), options: .storageModeShared)
        
        let indexBuffer: MTLBuffer = Engine.device.makeBuffer(bytes: &indicies, length: UInt32.stride(indicies.count), options: .storageModeShared)!
        solid.mesh.indexBuffers = [indexBuffer]
        
        solid.mesh.materials = [material]
        
        addSolid(solid: solid)
    }
    
    func createCubeFace(_ cubeVertices: [SIMD3<Float>],_ color: SIMD3<Float>,_ reflectivity: Float, _ refractiveIndex: Float, _ i0: Int,_ i1: Int,_ i2: Int,_ i3: Int,_ inwardNormals: Bool,_ triangleMask: uint32) {
        
        let v0 = cubeVertices[i0]
        let v1 = cubeVertices[i1]
        let v2 = cubeVertices[i2]
        let v3 = cubeVertices[i3]
        
        var n0 = getTriangleNormal(v0: v0, v1: v1, S: v2)
        var n1 = getTriangleNormal(v0: v0, v1: v2, S: v3)
        
        if (inwardNormals) {
            n0 = -n0;
            n1 = -n1;
        }
        
        var opacity = 1.0
        if refractiveIndex >= 1.0 {
            opacity = 0
        }
        let material = Material(color: SIMD4<Float>(color, 1), isLit: true, opacity: Float(opacity), opticalDensity: refractiveIndex,  roughness: 1.0 - reflectivity, isTextureEnabled: false, isNormalMapEnabled: false, isMetallicMapEnabled: false, isRoughnessMapEnabled: false)
        
        addTriangle(v0: v0, v1: v1, v2: v2, n0: n0, material: material, triangleMaks: triangleMask)
        addTriangle(v0: v0, v1: v2, v2: v3, n0: n1, material: material, triangleMaks: triangleMask)
    }
    
    func createCube(faceMask: uint32, color: SIMD3<Float>, reflectivity: Float, refractiveIndex: Float = -1, transform: matrix_float4x4, inwardNormals: Bool, triangleMask: uint32) {
        
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
        
        if ((faceMask & Masks.FACE_MASK_NEGATIVE_X) != 0) {
            createCubeFace(cubeVertices, color, reflectivity, refractiveIndex, 0, 4, 6, 2, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_POSITIVE_X) != 0) {
            createCubeFace(cubeVertices, color, reflectivity, refractiveIndex, 1, 3, 7, 5, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_NEGATIVE_Y) != 0) {
            createCubeFace(cubeVertices, color, reflectivity, refractiveIndex, 0, 1, 5, 4, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_POSITIVE_Y) != 0) {
            createCubeFace(cubeVertices, color, reflectivity, refractiveIndex, 2, 6, 7, 3, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_NEGATIVE_Z) != 0) {
            createCubeFace(cubeVertices, color, reflectivity, refractiveIndex, 0, 2, 3, 1, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_POSITIVE_Z) != 0) {
            createCubeFace(cubeVertices, color, reflectivity, refractiveIndex, 4, 5, 7, 6, inwardNormals, triangleMask)
        }
    }
}
