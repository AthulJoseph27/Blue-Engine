import MetalKit

protocol Mesh {
    var vertices: [SIMD3<Float>] { get set }
    var normals:  [SIMD3<Float>] { get }
    var colors:   [SIMD3<Float>] { get }
    var masks:    [uint]         { get }
}

class CustomMesh: Mesh {
    internal var vertices: [SIMD3<Float>]
    internal var normals:  [SIMD3<Float>]
    internal var colors:   [SIMD3<Float>]
    internal var masks:    [uint]
    init() {
        self.vertices = []
        self.normals = []
        self.colors = []
        self.masks = []
        createMesh()
    }
    
    func createMesh(){}
    
    func computeNormal(vertices: [SIMD3<Float>])->SIMD3<Float> {
        let AB = vertices[1] - vertices[0]
        let AC = vertices[2] - vertices[0]
        
        return normalize(cross(AB, AC))
    }
    
    func addTriangle(vertices: [SIMD3<Float>], color: SIMD3<Float> = SIMD3<Float>(0.2, 0.4, 0.8), normal: SIMD3<Float>? = nil, mask: uint32 = Masks.TRIANGLE_MASK_GEOMETRY) {
        
        self.vertices.append(contentsOf: vertices)
        
        var nr = normal
        
        if nr == nil {
            nr = computeNormal(vertices: vertices)
        }
        
        for _ in 0..<3{
            normals.append(nr!)
            colors.append(color)
        }
        
        masks.append(mask)
    }
}

class TriangleMesh : CustomMesh {
    override func createMesh() {
        let vertices = [
            SIMD3<Float>(0, 0, 100),
            SIMD3<Float>(2160 ,0, 100),
            SIMD3<Float>(1080, 1440, 100)
        ]
        addTriangle(vertices: vertices, color: SIMD3<Float>(0, 1, 0))
    }
    
}

class QuadMesh : CustomMesh {
    override func createMesh() {
        let vertices = [
            SIMD3<Float>( 1080, 1080, 100),
            SIMD3<Float>(1080, 2160, 100),
            SIMD3<Float>(2160, 1080, 100),
            SIMD3<Float>( 2160, 2160, 100),
        ]
        addTriangle(vertices: [vertices[0], vertices[3], vertices[1]])
        addTriangle(vertices: [vertices[0], vertices[2], vertices[3]])
    }
}

class CubeMesh : CustomMesh {
    override func createMesh() {
        let vertices = [
            SIMD3<Float>(-540,-540,-540), // 0 0 0; 0
            SIMD3<Float>( 540,-540,-540), // 1 0 0; 1
            SIMD3<Float>( 540,-540, 540), // 1 0 1; 2
            SIMD3<Float>(-540,-540, 540), // 0 0 1; 3
            
            SIMD3<Float>(-540, 540,-540), // 0 1 0; 4
            SIMD3<Float>( 540, 540,-540), // 1 1 0; 5
            SIMD3<Float>( 540, 540, 540), // 1 1 1; 6
            SIMD3<Float>(-540, 540, 540), // 0 1 1; 7
        ]
        
        //Bottom Face
        addTriangle(vertices: [vertices[0], vertices[3], vertices[2]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, -1, 0))
        addTriangle(vertices: [vertices[0], vertices[2], vertices[1]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(0, -1, 0))
        
        //Top Face
        addTriangle(vertices: [vertices[4], vertices[7], vertices[6]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(0, 1, 0))
        addTriangle(vertices: [vertices[4], vertices[5], vertices[6]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, 1, 0))
        
        //Front Face
        addTriangle(vertices: [vertices[0], vertices[5], vertices[4]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(0, 0, 1))
        addTriangle(vertices: [vertices[0], vertices[1], vertices[5]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(0, 0, 1))
        
        //Back Face
        addTriangle(vertices: [vertices[3], vertices[7], vertices[6]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(0, 0, -1))
        addTriangle(vertices: [vertices[3], vertices[6], vertices[2]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(0, 0, -1))
        
        //Left Face
        addTriangle(vertices: [vertices[0], vertices[4], vertices[7]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(-1, 0, 0))
        addTriangle(vertices: [vertices[0], vertices[7], vertices[3]], color: SIMD3<Float>(1, 0, 0), normal: SIMD3<Float>(-1, 0, 0))
        
        //Right Face
        addTriangle(vertices: [vertices[1], vertices[6], vertices[5]], color: SIMD3<Float>(0, 1, 0), normal: SIMD3<Float>(1, 0, 0))
        addTriangle(vertices: [vertices[1], vertices[2], vertices[6]], color: SIMD3<Float>(0, 0, 1), normal: SIMD3<Float>(1, 0, 0))
        
    }
}

class ModelMesh: CustomMesh {
//    private var _meshes: [Any]!
    private var _modelName: String!

    init(modelName: String) {
        self._modelName = modelName
        super.init()
    }
    
    private func loadModel() {
        guard let assetUrl = Bundle.main.url(forResource: _modelName, withExtension: "obj") else {
            fatalError("Asset\(_modelName!) does not exist")
        }
        
        var triangles: [TriangleIn] = []
//        var textureFile: String = ""
        
        do {
            let contents = try String(contentsOf: assetUrl.absoluteURL)
            var lines = contents.split(separator:"\n")

            lines.removeAll(where: { $0.starts(with: "#") })
            
            var vertices: [SIMD3<Float>] = []
            var normals: [SIMD3<Float>] = []
            var uvCoordinates: [SIMD2<Float>] = []
            
            for line in lines {
                if line.prefix(2) == "v " {
                    let tmp = line.dropFirst(2).split(separator: " ")
                    let vertex = SIMD3<Float>(Float(tmp[0]) ?? 0.0, Float(tmp[1]) ?? 0.0, Float(tmp[2]) ?? 0.0)
                    vertices.append(vertex)
                } else if line.prefix(2) == "vn" {
                    let tmp = line.dropFirst(3).split(separator: " ")
                    let normal = SIMD3<Float>(Float(tmp[0]) ?? 0.0, Float(tmp[1]) ?? 0.0, Float(tmp[2]) ?? 0.0)
                    normals.append(normal)
                } else if line.prefix(2) == "vt" {
                    let tmp = line.dropFirst(3).split(separator: " ")
                    let uvCoord = SIMD2<Float>(Float(tmp[0]) ?? 0.0, Float(tmp[1]) ?? 0.0)
                    uvCoordinates.append(uvCoord)
                } else if line.first == "f" {
                    let currVertices = line.dropFirst(2).split(separator: " ")
                    var triangle = TriangleIn(vertices: [], normal: SIMD3<Float>(repeating: 0), color: SIMD4<Float>(repeating: 0), uvCoordinates: [])
                    
                    for i in 0..<3 {
                        let vertex = currVertices[i]
                        let tmp = vertex.split(separator: "/")
                        triangle.vertices.append((Int(tmp[0]) ?? 1) - 1)
                        triangle.uvCoordinates.append(uvCoordinates[(Int(tmp[1]) ?? 1) - 1])
                        triangle.normal = normals[(Int(tmp[2]) ?? 1) - 1]
                    }
                    
                    triangles.append(triangle)
                    
                    if currVertices.count == 4 {
                        triangle = TriangleIn(vertices: [], normal: SIMD3<Float>(repeating: 0), color: SIMD4<Float>(repeating: 0), uvCoordinates: [])
                        
                        for i in 0..<4 {
                            if i == 1 {
                                continue
                            }
                            
                            let vertex = currVertices[i]
                            let tmp = vertex.split(separator: "/")
                            triangle.vertices.append((Int(tmp[0]) ?? 1) - 1)
                            triangle.uvCoordinates.append(uvCoordinates[(Int(tmp[1]) ?? 1) - 1])
                            triangle.normal = normals[(Int(tmp[2]) ?? 1) - 1]
                        }
                        
                        triangles.append(triangle)
                    }
                    
                } else if line.prefix(6) == "mtllib" {
//                    textureFile = String(line.dropFirst(7))
                }
            }
            
            for triangle in triangles {
                let vi = triangle.vertices
                addTriangle(vertices: [vertices[vi[0]], vertices[vi[1]], vertices[vi[2]]], normal: triangle.normal)
            }
        } catch {
            print("Failed to load model")
        }
    }
    
    override func createMesh() {
        loadModel()
        var transform = matrix_identity_float4x4
        transform.scale(axis: SIMD3<Float>(repeating: 500))
        for i in 0..<vertices.count {
            let transformedVertex = transform * SIMD4<Float>(vertices[i], 1)
//            let transformedNormal = transform * SIMD4<Float>(normals[i], 1)
            vertices[i] = SIMD3<Float>(transformedVertex.x, transformedVertex.y, transformedVertex.z)
            normals[i] *= -1
        }
    }
}
