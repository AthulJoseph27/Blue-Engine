import MetalKit

class Scene {
    
    private var cameraManager = CameraManager()
    internal var uniform: Uniforms!
    internal var objects: [Solid] = []
    internal var triangles: [TriangleOut] = []
    internal var skyBox: MTLTexture!
    
    init(drawableSize: CGSize) {
        uniform = Uniforms(width: uint(drawableSize.width), height: uint(drawableSize.height), triangleCount: uint(triangles.count), skyBoxSize: SIMD2<Int32>(repeating: 0), isSkyBoxSet: true, cameraPositionDelta: SIMD3<Float>(repeating: 0), cameraRotation: SIMD3<Float>(repeating: 0))
        skyBox = Skyboxibrary.skybox(.Beach)
        buildScene()
    }
    
    func buildScene() {}
    
    func addCamera(_ camera:Camera, _ setAsCurrentCamera: Bool = true) {
        cameraManager.registerCamera(camera: camera)
        if(setAsCurrentCamera) {
            cameraManager.setCamera(camera.cameraType)
        }
    }
    
    func updateCameras(deltaTime: Float) {
        cameraManager.update(deltaTime: deltaTime)
    }
    
    func render(renderCommandEncoder: MTLComputeCommandEncoder) {
        let _triangleBuffer = Engine.device.makeBuffer(bytes: triangles, length: TriangleOut.stride(triangles.count), options: [])
        
        uniform.cameraPositionDelta = cameraManager.currentCamera.position
        uniform.cameraRotation = cameraManager.currentCamera.rotation
        
        if(skyBox != nil){
            uniform.skyBoxSize = SIMD2<Int32>(Int32(skyBox!.width), Int32(skyBox!.height))
            renderCommandEncoder.setTexture(skyBox!, index: 1)
        }
            
        let _uniformBuffer = Engine.device.makeBuffer(bytes: &uniform, length: Uniforms.stride, options: [])
        
        renderCommandEncoder.setBuffer(_triangleBuffer, offset: 0, index: 0)
        renderCommandEncoder.setBuffer(_uniformBuffer, offset: 0, index: 1)
        
        var rotationMatrix = cameraManager.currentCamera.rotationMatrix
        
        renderCommandEncoder.setBytes(&rotationMatrix, length: RotationMatrix.stride, index: 2)
    }
}
