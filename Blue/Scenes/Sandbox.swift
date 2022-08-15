import MetalKit

class SandboxScene: Scene {
    let gameObject = GameObject(meshTypes: MeshTypes.Quad)
    var cube = Cube()
    var debugCamera = DebugCamera()
    
    override func buildScene() {
        addCamera(debugCamera)
         
        debugCamera.position.z = 100
        
        addCubes()
    }
    
    func addCubes() {
        let cubeCollection = CubeCollection(cubesWide: 20, cubesHigh: 20, cubesBack: 20)
        addChild(cubeCollection)
        
    }
    
    override func update(deltaTime: Float) {
        cube.rotation.x += deltaTime
        cube.rotation.y += deltaTime
        super.update(deltaTime: deltaTime)
    }
}
