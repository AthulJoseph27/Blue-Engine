import MetalKit

protocol Mesh {
    var vertices: [SIMD3<Float>] { get set }
    var normals: [SIMD3<Float>] { get }
    var color: SIMD4<Float> { get }
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder)
}

class Triangle: Mesh, sizeable {
    var vertices: [SIMD3<Float>] = []
    var vertexIndex: [Int] = []
    var normals: [SIMD3<Float>]
    var color: SIMD4<Float>
    
    init(_ vertices: [SIMD3<Float>], color: SIMD4<Float> = SIMD4<Float>(0.2, 0.4, 0.8, 1.0)) {
        self.vertices = vertices
        self.vertexIndex = []
        self.normals = []
        self.color = color
    }
    
    func computeNormal() {
        let AB = vertices[1] - vertices[0]
        let AC = vertices[2] - vertices[0]
        
        self.normals = [cross(AB, AC)]
    }
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        
    }
}

class CustomMesh: Mesh {
//    var vertices: [Vertex]
    internal var vertices: [SIMD3<Float>]
    internal var normals: [SIMD3<Float>]
    internal var color: SIMD4<Float>
    internal var triangles: [Triangle]
    private var _vertexBuffer: MTLBuffer!
    
    init() {
        self.vertices = []
        self.normals = []
        self.color = SIMD4<Float>(0.8, 0.8, 0.8, 1.0)
        self.triangles = []
        createVertices()
    }
    
    func createVertices() {}
    
    func createBuffers() {
        _vertexBuffer = Engine.device.makeBuffer(bytes:vertices, length: Vertex.stride(vertices.count), options: [])
    }
    
    func addTriangle(vertices: [Int], color: SIMD4<Float> = SIMD4<Float>(0.2, 0.4, 0.8, 1.0), normal: SIMD3<Float>? = nil) {
        let triangle = Triangle([], color: color)
        
        for index in vertices {
            triangle.vertices.append(self.vertices[index])
            triangle.vertexIndex.append(index)
        }
        
        if normal == nil {
            triangle.computeNormal()
        } else {
            triangle.normals = [normal!]
        }
        
        triangles.append(triangle)
    }
        
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0,index: 0)
    }
}

class TriangleMesh : CustomMesh {
    override func createVertices() {
        self.vertices = [
            SIMD3<Float>(0, 0, 100),
            SIMD3<Float>(2160 ,0, 100),
            SIMD3<Float>(1080, 1440, 100)
        ]
        addTriangle(vertices: [0, 1, 2])
    }
    
}

class QuadMesh : CustomMesh {
    override func createVertices() {
        self.vertices = [
            SIMD3<Float>( 1080, 1080, 100),
            SIMD3<Float>(1080, 2160, 100),
            SIMD3<Float>(2160, 1080, 100),
            SIMD3<Float>( 2160, 2160, 100),
        ]
        addTriangle(vertices: [0, 3, 1])
        addTriangle(vertices: [0, 2, 3])
    }
}

class CubeMesh : CustomMesh {
    override func createVertices() {
        self.vertices = [
            SIMD3<Float>( 1080, 880, 1080), // 0 0 0; 0
            SIMD3<Float>( 2160, 880, 1080), // 1 0 0; 1
            SIMD3<Float>( 2160, 880, 2160), // 1 0 1; 2
            SIMD3<Float>( 1080, 880, 2160), // 0 0 1; 3
            
            SIMD3<Float>( 1080, 1960, 1080), // 0 1 0; 4
            SIMD3<Float>( 2160, 1960, 1080), // 1 1 0; 5
            SIMD3<Float>( 2160, 1960, 2160), // 1 1 1; 6
            SIMD3<Float>( 1080, 1960, 2160), // 0 1 1; 7
        ]
        
        //Bottom Face
        addTriangle(vertices: [0, 3, 2], color: SIMD4<Float>(1, 0, 0, 1))
        addTriangle(vertices: [0, 2, 1], color: SIMD4<Float>(0, 1, 0, 1))
        
        //Top Face
        addTriangle(vertices: [4, 7, 6], color: SIMD4<Float>(0, 0, 1, 1))
        addTriangle(vertices: [4, 5, 6], color: SIMD4<Float>(1, 0, 0, 1))
        
        //Front Face
        addTriangle(vertices: [0, 5, 4], color: SIMD4<Float>(0, 1, 0, 1))
        addTriangle(vertices: [0, 1, 5], color: SIMD4<Float>(0, 0, 1, 1))
        
        //Back Face
        addTriangle(vertices: [3, 7, 6], color: SIMD4<Float>(1, 0, 0, 1))
        addTriangle(vertices: [3, 6, 2], color: SIMD4<Float>(0, 1, 0, 1))
        
        //Left Face
        addTriangle(vertices: [0, 4, 7], color: SIMD4<Float>(0, 0, 1, 1))
        addTriangle(vertices: [0, 7, 3], color: SIMD4<Float>(1, 0, 0, 1))
        
        //Right Face
        addTriangle(vertices: [1, 6, 2], color: SIMD4<Float>(0, 1, 0, 1))
        addTriangle(vertices: [1, 2, 5], color: SIMD4<Float>(0, 0, 1, 1))
        
    }
}

class ModelMesh: CustomMesh {
//    private var _meshes: [Any]!
    private var _modelName: String!

    init(modelName: String) {
        self._modelName = modelName
        super.init()
    }
    
    private func loadModel()->ModelData {
        guard let assetUrl = Bundle.main.url(forResource: _modelName, withExtension: "obj") else {
            fatalError("Asset\(_modelName!) does not exist")
        }
        
        var triangles: [TriangleIn] = []
        var textureFile: String = ""
        
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
                    
                    for vertex in currVertices {
                        let tmp = vertex.split(separator: "/")
                        triangle.vertices.append(vertices[(Int(tmp[0]) ?? 1) - 1])
                        triangle.uvCoordinates.append(uvCoordinates[(Int(tmp[1]) ?? 1) - 1])
                        triangle.normal = normals[(Int(tmp[2]) ?? 1) - 1]
                    }
                    
                    triangles.append(triangle)
//                    print(triangle)
                } else if line.prefix(6) == "mtllib" {
                    textureFile = String(line.dropFirst(7))
                }
            }
        } catch {
            return ModelData(textureFile: "", triangles: [])
        }
        
        return ModelData(textureFile: textureFile, triangles: triangles)
    }
    
    override func createVertices() {
//        let modelData = loadModel()
        
//        for triangle in modelData.triangles {
//            addTriangle(vertices: triangle.vertices, normal: triangle.normal)
//        }
    }
}
