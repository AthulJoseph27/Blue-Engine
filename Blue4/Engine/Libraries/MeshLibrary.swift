import MetalKit
import simd

enum MeshTypes {
    case None
    case Plane
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
    private static var meshes: [MeshTypes: Mesh] = [:]
    
    public static func initialize() {
        createDefaultMeshes()
    }
    
    private static func createDefaultMeshes() {
        meshes.updateValue(Mesh(modelName: "Plane"), forKey: .Plane)
        meshes.updateValue(Mesh(modelName: "Cube"), forKey: .Cube)
        meshes.updateValue(Mesh(modelName: "Sphere"), forKey: .Sphere)
        meshes.updateValue(Mesh(modelName: "Icosphere"), forKey: .Icosphere)
        meshes.updateValue(Mesh(modelName: "Cylinder"), forKey: .Cylinder)
        meshes.updateValue(Mesh(modelName: "Cone"), forKey: .Cone)
        meshes.updateValue(Mesh(modelName: "Torus"), forKey: .Torus)
        meshes.updateValue(Mesh(modelName: "Monkey"), forKey: .Monkey)
        meshes.updateValue(Mesh(modelName: "E 45 Aircraft_obj"), forKey: .SpaceShip)
        meshes.updateValue(Mesh(modelName: "chest"), forKey: .Chest)
        meshes.updateValue(Mesh(modelName: "fireplace_room"), forKey: .FireplaceRoom)
    }
    
    public static func mesh(_ meshTypes: MeshTypes)->Mesh{
        return meshes[meshTypes]!
    }
}
