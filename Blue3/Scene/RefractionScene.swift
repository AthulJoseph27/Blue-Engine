import MetalKit

class RefractionScene: Scene {
    var camera = DebugCamera()
    
    override func buildScene() {
        materials.append(Material())
        textures.append(nil)
        normalMapTextures.append(nil)
        metallicMapTextures.append(nil)
        roughnessMapTextures.append(nil)
        skyBox = Skyboxibrary.skybox(.NightCity)
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
//
//        // Right wall
        createCube(faceMask: Masks.FACE_MASK_POSITIVE_X, color: SIMD3<Float>([0.14, 0.45, 0.091]), reflectivity: 0.0, transform: transform, inwardNormals: true, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

//         Short box
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(0.3275, 0.3, 0.3725))
        transform.rotate(angle: -0.3, axis: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.3, 0.3, 0.3))
        
        let monkey = Solid(.Monkey)
        monkey.setColor(SIMD4<Float>(0.2, 0.2, 0.8, 1.0))
        monkey.setRoughness(1.0)
        monkey.enableTexture(false)
        monkey.overrideMeshMaterial()
        
        addObject(solid: monkey, transform: transform)
        
        transform.scale(axis: SIMD3<Float>(0.0, 0.0, 0.0))
        createCube(faceMask: Masks.FACE_MASK_ALL, color: SIMD3<Float>([0.725, 0.71, 0.68]), reflectivity: 0.0, refractiveIndex: -1.2, transform: transform, inwardNormals: false, triangleMask: uint(TRIANGLE_MASK_GEOMETRY))

//         Tall box
        transform = matrix_identity_float4x4
        transform.translate(direction: SIMD3<Float>(-0.375, 0.5, -0.29))
        transform.rotate(angle: 0.3, axis: SIMD3<Float>(0, 1, 0))
        transform.scale(axis: SIMD3<Float>(0.008, 0.008, 0.008))
        
        let chest = Solid(.Chest)
//        monkey.setColor(SIMD4<Float>(0.2, 0.2, 0.8, 1.0))
//        monkey.setRoughness(1.0)
//        monkey.enableTexture(false)
//        monkey.overrideMeshMaterial()
        addObject(solid: chest, transform: transform)
    }
    
    func createCubeFace(_ vertices: inout [SIMD3<Float>],_ normals: inout [SIMD3<Float>],_ colors: inout [SIMD3<Float>], _ cubeVertices: [SIMD3<Float>],_ color: SIMD3<Float>,_ reflectivity: Float, _ refractiveIndex: Float, _ i0: Int,_ i1: Int,_ i2: Int,_ i3: Int,_ inwardNormals: Bool,_ triangleMask: uint32) {
        
        let v0 = cubeVertices[i0]
        let v1 = cubeVertices[i1]
        let v2 = cubeVertices[i2]
        let v3 = cubeVertices[i3]
        
        var n0 = self.getTriangleNormal(v0: v0, v1: v1, S: v2)
        var n1 = self.getTriangleNormal(v0: v0, v1: v2, S: v3)
        
        if (inwardNormals) {
            n0 = -n0;
            n1 = -n1;
        }
        
        vertices.append(v0)
        vertices.append(v1)
        vertices.append(v2)
        vertices.append(v0)
        vertices.append(v2)
        vertices.append(v3)
        
        for _ in 0..<3 {
            normals.append(n0)
            materialIds.append(uint(materials.count))
            textureIds.append(0)
            
        }
        
        for _ in 0..<3 {
            normals.append(n1)
            materialIds.append(uint(materials.count))
            textureIds.append(0)
        }
        
        var opacity = 1.0
        
        if refractiveIndex >= 1.0 {
            opacity = 0
        }
        
        materials.append(Material(color: SIMD4<Float>(color, 1), opacity: Float(opacity), opticalDensity: refractiveIndex,  roughness: 1.0 - reflectivity, isTextureEnabled: false, isNormalMapEnabled: false, isMetallicMapEnabled: false, isRoughnessMapEnabled: false))
        
        for _ in 0..<6 {
            colors.append(color)
        }
        
        for _ in 0..<2 {
            masks.append(triangleMask)
        }
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
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, reflectivity, refractiveIndex, 0, 4, 6, 2, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_POSITIVE_X) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, reflectivity, refractiveIndex, 1, 3, 7, 5, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_NEGATIVE_Y) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, reflectivity, refractiveIndex, 0, 1, 5, 4, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_POSITIVE_Y) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, reflectivity, refractiveIndex, 2, 6, 7, 3, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_NEGATIVE_Z) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, reflectivity, refractiveIndex, 0, 2, 3, 1, inwardNormals, triangleMask)
        }
        
        if ((faceMask & Masks.FACE_MASK_POSITIVE_Z) != 0) {
            createCubeFace(&vertices, &normals, &colors, cubeVertices, color, reflectivity, refractiveIndex, 4, 5, 7, 6, inwardNormals, triangleMask)
        }
    }
}
