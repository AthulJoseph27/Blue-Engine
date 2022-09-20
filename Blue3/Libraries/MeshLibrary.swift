import MetalKit
import simd

enum MeshTypes {
    case Triangle
    case Quad
    case Cube
    case Sphere
    case Icosphere
    case Cylinder
    case Cone
    case Torus
    case Monkey
}

class MeshLibrary {
    private static var meshes: [MeshTypes: CustomMesh] = [:]
    
    public static func initialize() {
        createDefaultMeshes()
    }
    
    private static func createDefaultMeshes() {
        meshes.updateValue(TriangleMesh(), forKey: .Triangle)
        meshes.updateValue(QuadMesh(), forKey: .Quad)
        meshes.updateValue(ModelMesh(modelName: "Cube"), forKey: .Cube)
        meshes.updateValue(ModelMesh(modelName: "Sphere"), forKey: .Sphere)
        meshes.updateValue(ModelMesh(modelName: "Icosphere"), forKey: .Icosphere)
        meshes.updateValue(ModelMesh(modelName: "Cylinder"), forKey: .Cylinder)
        meshes.updateValue(ModelMesh(modelName: "Cone"), forKey: .Cone)
        meshes.updateValue(ModelMesh(modelName: "Torus"), forKey: .Torus)
        meshes.updateValue(ModelMesh(modelName: "Monkey"), forKey: .Monkey)
    }
    
    public static func mesh(_ meshTypes: MeshTypes)->CustomMesh{
        return meshes[meshTypes]!
    }
}
