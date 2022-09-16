import simd

class DebugCamera: SceneCamera {
    var cameraType: CameraTypes = CameraTypes.Debug
    
    var position = SIMD3<Float>(1080, 720, -1200)
    var deltaPosition = SIMD3<Float>(repeating: 0)
    var rotation = SIMD3<Float>(0, 0, 0)
    var deltaRotation = SIMD3<Float>(0, 0, 0)

    
    func update(deltaTime: Float) {

        if(Keyboard.isKeyPressed(.leftArrow)) {
            self.deltaPosition.x -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.rightArrow)) {
            self.deltaPosition.x += deltaTime
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
            self.deltaPosition.z -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.s)) {
            self.deltaPosition.z += deltaTime
        }
        
        if(Keyboard.isKeyPressed(.z)) {
            self.deltaRotation.x -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.x)) {
            self.deltaRotation.x += deltaTime
        }
        
    }
    
    
}
