import MetalKit

class Solid: Node {
    var meshType: MeshTypes
    var mesh: Mesh
    var lightSource = false
    var animated = false
    var transformedVertexBuffer: MTLBuffer?
    var mergedIndexBuffer:     MTLBuffer!
    
    init(_ meshType: MeshTypes, ligthSource: Bool = false) {
        self.meshType = meshType
        self.lightSource = ligthSource
        self.mesh = MeshLibrary.mesh(meshType)
        super.init()
    }
    
    override func update(deltaTime: Float) {
    }
}
