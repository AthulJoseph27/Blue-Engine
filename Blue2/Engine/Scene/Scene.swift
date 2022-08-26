import MetalKit

class Scene {
    
    private var cameraManager = CameraManager()
//    private var sceneConstants = SceneConstants()
    private var modelConstants: [ModelConstants] = []
    
    internal var uniform: Uniforms!
    internal var objects: [Solid] = []
    internal var vertices: [VertexOut] = []
    internal var triangles: [TriangleOut] = []
    internal var skyBox: MTLTexture!
    
    init(drawableSize: CGSize) {
        uniform = Uniforms(width: uint(drawableSize.width), height: uint(drawableSize.height), triangleCount: uint(triangles.count), verticesCount: uint(vertices.count), skyBoxSize: SIMD2<Int32>(repeating: 0), isSkyBoxSet: true, cameraPositionDelta: SIMD3<Float>(repeating: 0), cameraRotation: SIMD3<Float>(repeating: 0))
        skyBox = Skyboxibrary.skybox(.Jungle)
        buildScene()
    }
    
    func buildScene() {}
    
    func updateObjects(deltaTime: Float) {}
    
    func addSolid(solid: Solid) {
        objects.append(solid)
        addTriangles(mesh: solid.mesh!)
        uniform.triangleCount = uint(triangles.count)
        uniform.verticesCount = uint(vertices.count)
    }
    
    func addTriangles(mesh: CustomMesh) {
        let count: Int = self.vertices.count
        let currObjIndex: uint = uint(self.objects.count - 1)
        
        for vertex in mesh.vertices {
            self.vertices.append(VertexOut(index: currObjIndex, position: vertex))
        }

        for triangle in mesh.triangles {
            let triangleOut = TriangleOut(A: uint(count + triangle.vertexIndex[0]),B: uint(count + triangle.vertexIndex[1]), C: uint(count + triangle.vertexIndex[2]), normal: triangle.normals[0], color: triangle.color)
            triangles.append(triangleOut)
        }
    }
    
    func addCamera(_ camera:Camera, _ setAsCurrentCamera: Bool = true) {
        cameraManager.registerCamera(camera: camera)
        if(setAsCurrentCamera) {
            cameraManager.setCamera(camera.cameraType)
        }
    }
    
    func updateSceneConstants() {
//        sceneConstants.projectionMatrix = cameraManager.currentCamera.projectionMatrix
    }
    
    func update() {
        updateSceneConstants()
        updateModelConstants()
    }
    
    func updateCameras(deltaTime: Float) {
        cameraManager.update(deltaTime: deltaTime)
    }
    
    func updateBuffers(renderCommandEncoder: MTLComputeCommandEncoder) {
        let _verticesBufferIn = Engine.device.makeBuffer(bytes: vertices, length: VertexOut.stride(vertices.count), options: [])
        let _verticesBufferOut = Engine.device.makeBuffer(bytes: vertices, length: VertexOut.stride(vertices.count), options: [])
        
        let _triangleBuffer = Engine.device.makeBuffer(bytes: triangles, length: TriangleOut.stride(triangles.count), options: [])
        
        uniform.cameraPositionDelta = cameraManager.currentCamera.position
        uniform.cameraRotation = cameraManager.currentCamera.rotation
        
        if(skyBox != nil){
            uniform.skyBoxSize = SIMD2<Int32>(Int32(skyBox!.width), Int32(skyBox!.height))
            renderCommandEncoder.setTexture(skyBox!, index: 1)
        }
            
        let _uniformBuffer = Engine.device.makeBuffer(bytes: &uniform, length: Uniforms.stride, options: [])
        
        
        let _modelConstantsBuffer = Engine.device.makeBuffer(bytes: &modelConstants, length: ModelConstants.stride(modelConstants.count), options: [])
//        let _sceneConstantsBuffer = Engine.device.makeBuffer(bytes: &sceneConstants, length: SceneConstants.stride, options: [])
        
        
        renderCommandEncoder.setBuffer(_verticesBufferIn, offset: 0, index: 0)
        renderCommandEncoder.setBuffer(_verticesBufferOut, offset: 0, index: 1)
        renderCommandEncoder.setBuffer(_triangleBuffer, offset: 0, index: 2)
        renderCommandEncoder.setBuffer(_uniformBuffer, offset: 0, index: 3)
        renderCommandEncoder.setBuffer(_modelConstantsBuffer, offset: 0, index: 4)
//        renderCommandEncoder.setBuffer(_sceneConstantsBuffer, offset: 0, index: 5)
        
        var rotationMatrix = cameraManager.currentCamera.rotationMatrix
        renderCommandEncoder.setBytes(&rotationMatrix, length: RotationMatrix.stride, index: 6)
        

    }
    
    private func updateModelConstants() {
        modelConstants = []
        for solid in objects {
            modelConstants.append(solid.modelContants)
        }
    }
}
