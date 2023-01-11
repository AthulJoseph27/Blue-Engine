import MetalKit
import simd

enum MeshTypes {
    case None
    case Triangle
    case Quad
    case Cube
    case Sphere
    case Icosphere
    case Cylinder
    case Cone
    case Torus
    case Monkey
    case SpaceShip
    case Chest
    case FireplaceRoom
}

class MeshLibrary {
    private static var meshes: [MeshTypes: CustomMesh] = [:]
    
    public static func initialize() {
        createDefaultMeshes()
    }
    
    private static func createDefaultMeshes() {
        meshes.updateValue(CustomMesh(), forKey: .None)
        meshes.updateValue(TriangleMesh(), forKey: .Triangle)
        meshes.updateValue(QuadMesh(), forKey: .Quad)
        meshes.updateValue(ModelMesh(modelName: "Cube"), forKey: .Cube)
        meshes.updateValue(ModelMesh(modelName: "Sphere"), forKey: .Sphere)
        meshes.updateValue(ModelMesh(modelName: "Icosphere"), forKey: .Icosphere)
        meshes.updateValue(ModelMesh(modelName: "Cylinder"), forKey: .Cylinder)
        meshes.updateValue(ModelMesh(modelName: "Cone"), forKey: .Cone)
        meshes.updateValue(ModelMesh(modelName: "Torus"), forKey: .Torus)
        meshes.updateValue(ModelMesh(modelName: "Monkey"), forKey: .Monkey)
        meshes.updateValue(ModelMesh(modelName: "E 45 Aircraft_obj"), forKey: .SpaceShip)
        meshes.updateValue(ModelMesh(modelName: "chest"), forKey: .Chest)
        meshes.updateValue(ModelMesh(modelName: "fireplace_room"), forKey: .FireplaceRoom)
    }
    
    public static func mesh(_ meshTypes: MeshTypes)->CustomMesh{
        return meshes[meshTypes]!
    }
}
