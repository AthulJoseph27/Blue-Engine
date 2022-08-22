import MetalKit

class Solid: Node {
    var mesh: CustomMesh!
    var modelContants = ModelConstants()
    
    init(_ meshType: MeshTypes) {
        mesh = MeshLibrary.mesh(meshType)
    }
    
    override func update(deltaTime: Float) {
//        self.rotation.z = -atan2(Mouse.getMouseViewportPosition().x - position.x, Mouse.getMouseViewportPosition().y - position.y)
        updateModelContants()
    }
    
    private func updateModelContants() {
        modelContants.modelMatrix = self.modelMatrix
    }
}
