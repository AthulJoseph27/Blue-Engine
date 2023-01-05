import simd

class DebugCamera: SceneCamera {
    var cameraType: CameraTypes = CameraTypes.Debug
    
    var position = SIMD3<Float>(0, 70, 405)
    var deltaPosition = SIMD3<Float>(0, 0, 0)
    var rotation = SIMD3<Float>(0, 0, 0)
    var deltaRotation = SIMD3<Float>(0, 0, 0)
    var projectionMatrix: matrix_float4x4 {
        return matrix_float4x4.prespective(degreeFov: 45, aspectRatio: 16.0/9.0, near: 0.1, far: 1000)
    }
    
    func update(deltaTime: Float) {
        
        if(Keyboard.isKeyPressed(.leftArrow)) {
            self.deltaPosition.x -= deltaTime * 100
        }
        
        if(Keyboard.isKeyPressed(.rightArrow)) {
            self.deltaPosition.x += deltaTime * 100
        }
        
        if(Keyboard.isKeyPressed(.downArrow)) {
            self.deltaPosition.y -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.upArrow)) {
            self.deltaPosition.y  += deltaTime
        }
        
        if(Keyboard.isKeyPressed(.a)) {
            self.deltaRotation.y += deltaTime
        }
        
        if(Keyboard.isKeyPressed(.d)) {
            self.deltaRotation.y -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.w)) {
            self.deltaPosition.z -= deltaTime * 100
        }
        
        if(Keyboard.isKeyPressed(.s)) {
            self.deltaPosition.z += deltaTime * 100
        }
        
        if(Keyboard.isKeyPressed(.z)) {
            self.deltaRotation.x -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.x)) {
            self.deltaRotation.x += deltaTime
        }
    }
    
    
}
