import simd

class DebugCamera: Camera {
    var cameraType: CameraTypes = CameraTypes.Debug
    
    var position: SIMD3<Float> = SIMD3<Float>(repeating: 0)
    var projectionMatrix: matrix_float4x4 {
        return matrix_float4x4.prespective(degreeFov: 45, aspectRatio: Renderer.AspectRatio, near: 0.1, far: 1000)
    }
    
    func update(deltaTime: Float) {
        if(Keyboard.isKeyPressed(.leftArrow)) {
            self.position.x += deltaTime
        }
        
        if(Keyboard.isKeyPressed(.rightArrow)) {
            self.position.x -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.downArrow)) {
            self.position.y += deltaTime
        }
        
        if(Keyboard.isKeyPressed(.upArrow)) {
            self.position.y  -= deltaTime
        }
    }
    
    
}
