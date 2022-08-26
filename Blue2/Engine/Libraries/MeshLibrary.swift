import MetalKit
import simd

enum MeshTypes {
    case Triangle
    case Quad
    case Cube
    case Sphere
}

class MeshLibrary {
    private static var meshes: [MeshTypes: CustomMesh] = [:]
    
    public static func initialize() {
        createDefaultMeshes()
    }
    
    private static func createDefaultMeshes() {
        meshes.updateValue(TriangleMesh(), forKey: .Triangle)
        meshes.updateValue(QuadMesh(), forKey: .Quad)
        meshes.updateValue(CubeMesh(), forKey: .Cube)
//        meshes.updateValue(ModelMesh(modelName: "Cube"), forKey: .Cube)
    }
    
    public static func mesh(_ meshTypes: MeshTypes)->CustomMesh{
        return meshes[meshTypes]!
    }
}