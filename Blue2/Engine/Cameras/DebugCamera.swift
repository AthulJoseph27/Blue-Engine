import simd

class DebugCamera: Camera {
    var cameraType: CameraTypes = CameraTypes.Debug
    
    var position = SIMD3<Float>(repeating: 0)
    var rotation = SIMD3<Float>(repeating: 0)
    
    func update(deltaTime: Float) {
        let dt = deltaTime * 100.0
        
        if(Keyboard.isKeyPressed(.leftArrow)) {
            self.position.x -= dt
        }
        
        if(Keyboard.isKeyPressed(.rightArrow)) {
            self.position.x += dt
        }
        
        if(Keyboard.isKeyPressed(.downArrow)) {
            self.position.y -= dt
        }
        
        if(Keyboard.isKeyPressed(.upArrow)) {
            self.position.y  += dt
        }
        
        if(Keyboard.isKeyPressed(.a)) {
            self.rotation.y -= deltaTime;
        }
        
        if(Keyboard.isKeyPressed(.d)) {
            self.rotation.y += deltaTime;
        }
        
    }
    
    
}
