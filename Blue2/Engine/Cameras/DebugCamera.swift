import simd

class DebugCamera: Camera {
    var cameraType: CameraTypes = CameraTypes.Debug
    
    var position = SIMD3<Float>(1080, 720, -1200)
    var deltaPosition = SIMD3<Float>(repeating: 0)
    var rotation = SIMD3<Float>(repeating: 0)
//    var projectionMatrix: matrix_float4x4 {
//        return matrix_float4x4.prespective(degreeFov: 45, aspectRatio: 16.0/9.0, near: 0, far: 1000)
//    }
    
    func update(deltaTime: Float) {
        let dt = deltaTime * 5.0
        
        if(Keyboard.isKeyPressed(.leftArrow)) {
            self.deltaPosition.x -= (dt * 100)
        }
        
        if(Keyboard.isKeyPressed(.rightArrow)) {
            self.deltaPosition.x += (dt * 100)
        }
        
        if(Keyboard.isKeyPressed(.downArrow)) {
            self.deltaPosition.y -= (dt * 100)
        }
        
        if(Keyboard.isKeyPressed(.upArrow)) {
            self.deltaPosition.y  += (dt * 100)
        }
        
        if(Keyboard.isKeyPressed(.a)) {
            self.rotation.y -= dt;
        }
        
        if(Keyboard.isKeyPressed(.d)) {
            self.rotation.y += dt;
        }
        
        if(Keyboard.isKeyPressed(.w)) {
            self.deltaPosition.z += dt * 100;
        }
        
        if(Keyboard.isKeyPressed(.s)) {
            self.deltaPosition.z -= dt * 100;
        }
        
    }
    
    
}
