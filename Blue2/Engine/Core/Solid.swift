import MetalKit

class Solid: Node {
    var mesh: CustomMesh!
    var modelContants = ModelConstants()
    
    init(_ meshType: MeshTypes) {
        super.init()
        mesh = MeshLibrary.mesh(meshType)
    }
    
    override func update(deltaTime: Float) {
        updateModelContants()
    }
    
    private func updateModelContants() {
        modelContants.modelMatrix = self.modelMatrix
    }
}
