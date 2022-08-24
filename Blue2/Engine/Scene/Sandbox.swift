import MetalKit

class Sandbox: Scene {
    var camera = DebugCamera()
    
    override func buildScene() {
        addCamera(camera)
        addSolid(meshType: .Quad)
    }
    
    public func addSolid(meshType: MeshTypes) {
        let solid = Solid(meshType)
        objects.append(solid)
        addTriangles(mesh: solid.mesh!)
        uniform.triangleCount = uint(triangles.count)
    }
    
    public func addTriangles(mesh: CustomMesh) {
        for triangle in mesh.triangles {
            let vertices = triangle.vertices
            let triangleOut = TriangleOut(A: vertices[0].position,B: vertices[1].position, C: vertices[2].position, normals: triangle.normals[0], color: triangle.color)
            triangles.append(triangleOut)
        }
    }
}
