import MetalKit

protocol Mesh {
    var vertices: [Vertex] { get set }
    var normals: [SIMD3<Float>] { get }
    var color: SIMD4<Float> { get }
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder)
}

class Triangle: Mesh, sizeable {
    var vertices: [Vertex] = []
    var normals: [SIMD3<Float>]
    var color: SIMD4<Float>
    
    init(_ vertices: [Vertex], color: SIMD4<Float> = SIMD4<Float>(0.2, 0.4, 0.8, 1.0)) {
        self.vertices = vertices
        self.normals = []
        self.color = color
    }
    
    func computeNormal() {
        let AB = vertices[1].position - vertices[0].position
        let AC = vertices[2].position - vertices[0].position
        
        self.normals = [cross(AB, AC)]
    }
    
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        
    }
}

class CustomMesh: Mesh {
    internal var vertices: [Vertex]
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
//        createBuffers()
    }
    
    func createVertices() {}
    
    func createBuffers() {
        _vertexBuffer = Engine.device.makeBuffer(bytes:vertices, length: Vertex.stride(vertices.count), options: [])
    }
    
    func addTriangle(vertices: [SIMD3<Float>], color: SIMD4<Float> = SIMD4<Float>(0.2, 0.4, 0.8, 1.0)) {
        let triangle = Triangle([], color: color)
        
        for position in vertices {
            let vertex = Vertex(position: position, color: color)
            self.vertices.append(vertex)
            triangle.vertices.append(vertex)
        }
        
        triangle.computeNormal()
        triangles.append(triangle)
    }
        
    func drawPrimitives(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setVertexBuffer(_vertexBuffer, offset: 0,index: 0)
    }
}

class TriangleMesh : CustomMesh {
    override func createVertices() {
        let vertices = [
            SIMD3<Float>(0, 0, 100),
            SIMD3<Float>(2160 ,0, 100),
            SIMD3<Float>(1080, 1440, 100)
        ]
        addTriangle(vertices: vertices)
    }
    
}

class QuadMesh : CustomMesh {
    override func createVertices() {
        let vertices = [
            SIMD3<Float>( 2160, 2160, 100),
            SIMD3<Float>(1080, 2160, 100),
            SIMD3<Float>(1080, 1080, 100),
            SIMD3<Float>( 2160, 2160, 100),
            SIMD3<Float>(1080, 1080, 100),
            SIMD3<Float>( 2160, 1080, 100),
        ]
        addTriangle(vertices: [vertices[0],vertices[1],vertices[2]])
        addTriangle(vertices: [vertices[3],vertices[4],vertices[5]])
    }
}

class CubeMesh : CustomMesh {
    override func createVertices() {
        
        let vertices = [
            SIMD3<Float>(-100.0,-100.0,-100.0),
            SIMD3<Float>(-100.0,-100.0, 100.0),
            SIMD3<Float>(-100.0, 100.0, 100.0),
            SIMD3<Float>(-100.0,-100.0,-100.0),
            SIMD3<Float>(-100.0, 100.0, 100.0),
            SIMD3<Float>(-100.0, 100.0,-100.0),
            SIMD3<Float>( 100.0, 100.0, 100.0),
            SIMD3<Float>( 100.0,-100.0,-100.0),
            SIMD3<Float>( 100.0, 100.0,-100.0),
            SIMD3<Float>( 100.0,-100.0,-100.0),
            SIMD3<Float>( 100.0, 100.0, 100.0),
            SIMD3<Float>( 100.0,-100.0, 100.0),
            SIMD3<Float>( 100.0, 100.0, 100.0),
            SIMD3<Float>( 100.0, 100.0,-100.0),
            SIMD3<Float>(-100.0, 100.0,-100.0),
            SIMD3<Float>( 100.0, 100.0, 100.0),
            SIMD3<Float>(-100.0, 100.0,-100.0),
            SIMD3<Float>(-100.0, 100.0, 100.0),
            SIMD3<Float>( 100.0,-100.0, 100.0),
            SIMD3<Float>(-100.0,-100.0,-100.0),
            SIMD3<Float>( 100.0,-100.0,-100.0),
            SIMD3<Float>( 100.0,-100.0, 100.0),
            SIMD3<Float>(-100.0,-100.0, 100.0),
            SIMD3<Float>(-100.0,-100.0,-100.0),
            SIMD3<Float>( 100.0, 100.0,-100.0),
            SIMD3<Float>(-100.0,-100.0,-100.0),
            SIMD3<Float>(-100.0, 100.0,-100.0),
            SIMD3<Float>( 100.0, 100.0,-100.0),
            SIMD3<Float>( 100.0,-100.0,-100.0),
            SIMD3<Float>(-100.0,-100.0,-100.0),
            SIMD3<Float>(-100.0, 100.0, 100.0),
            SIMD3<Float>(-100.0,-100.0, 100.0),
            SIMD3<Float>( 100.0,-100.0, 100.0),
            SIMD3<Float>( 100.0, 100.0, 100.0),
            SIMD3<Float>(-100.0, 100.0, 100.0),
            SIMD3<Float>( 100.0,-100.0, 100.0)
        ]

        for i in stride(from: 0, to: (vertices.count-1), by: 3){
            addTriangle(vertices: [vertices[i], vertices[i+1], vertices[i+2]], color: SIMD4<Float>(0.2,0.4,0.8,1.0))
        }
    }
}
