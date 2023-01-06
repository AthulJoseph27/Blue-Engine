import MetalKit

class Solid: Node {
    var meshType: MeshTypes!
    var mesh: CustomMesh!
    var modelContants = ModelConstants()
    private var material = Material()
    
    init(_ meshType: MeshTypes) {
        super.init()
        self.meshType = meshType
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
    
    public func setRoughness(_ roughness: Float) {
        material.roughness = roughness
    }
    
    public func enableTexture(_ enable: Bool) {
        material.isTextureEnabled = enable
    }
    
    public func enableMaterial(_ enable: Bool) {
        material.isLit = enable;
    }
    
    public func overrideMeshMaterial() {
        mesh.materials = [material]
        
        let count = mesh.colors.count
        mesh.colors = []
        for _ in 0..<count {
            let color = material.color
            mesh.colors.append(SIMD3<Float>(color.x, color.y, color.z))
        }
    }
}
