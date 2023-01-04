import MetalKit

class Solid: Node {
    var mesh: CustomMesh!
    var modelContants = ModelConstants()
    private var material = Material()
    
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

extension Solid {
    public func setColor(_ color: SIMD4<Float>) {
        material.color = color
    }
}
