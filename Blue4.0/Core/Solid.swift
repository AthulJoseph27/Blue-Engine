import MetalKit

class Solid: Node {
    var meshType: MeshTypes
    var mesh: Mesh
    var lightSource = false
    var animated = false
    
    init(_ meshType: MeshTypes, ligthSource: Bool = false) {
        self.meshType = meshType
        self.lightSource = ligthSource
        if meshType == .None {
            self.mesh = Mesh(modelName: "None")
        } else {
            self.mesh = MeshLibrary.mesh(meshType)
        }
        super.init()
    }
    
    override func update(deltaTime: Float) {
    }
}

extension Solid {
    public func setColor(_ color: SIMD4<Float>) {
        mesh.materials[0].color = color
    }
    
    public func setRoughness(_ roughness: Float) {
        mesh.materials[0].roughness = roughness
    }
    
    public func setOpticalDensity(_ opticalDensity: Float) {
        mesh.materials[0].opticalDensity = opticalDensity
        mesh.materials[0].opacity = 0.9
    }
    
    public func enableTexture(_ enable: Bool) {
        mesh.materials[0].isTextureEnabled = enable
    }
    
    public func enableMaterial(_ enable: Bool) {
        mesh.materials[0].isLit = enable;
    }
}
