import simd

class DebugCamera: SceneCamera {
    var cameraType: CameraTypes = CameraTypes.Debug
    
    var position = SIMD3<Float>(0, 70, 405)
    var deltaPosition = SIMD3<Float>(0, 0, 0)
    var rotation = SIMD3<Float>(0, 0, 0)
    var deltaRotation = SIMD3<Float>(0, 0, 0)
    var rotationAboutOrigin = SIMD3<Float>(0, 0, 0)
    var deltaRotationAboutOrigin = SIMD3<Float>(0, 0, 0)
    var projectionMatrix: matrix_float4x4 {
        return matrix_float4x4.prespective(degreeFov: 45, aspectRatio: 16.0/9.0, near: 0.1, far: 1000)
    }
    
    func update(deltaTime: Float) {
        
        var _deltaPosition = SIMD3<Float>(0, 0, 0)
        
        if(Keyboard.isKeyPressed(.leftArrow)) {
            _deltaPosition.x -= deltaTime * 1
        }
        
        if(Keyboard.isKeyPressed(.rightArrow)) {
            _deltaPosition.x += deltaTime * 1
        }
        
        if(Keyboard.isKeyPressed(.downArrow)) {
            _deltaPosition.y -= deltaTime * 1
        }
        
        if(Keyboard.isKeyPressed(.upArrow)) {
            _deltaPosition.y  += deltaTime * 1
        }
        
        if(Keyboard.isKeyPressed(.w)) {
            _deltaPosition.z -= deltaTime * 1
        }
        
        if(Keyboard.isKeyPressed(.s)) {
            _deltaPosition.z += deltaTime * 1
        }
        
        if(Keyboard.isKeyPressed(.a)) {
            self.deltaRotation.y += deltaTime
        }
        
        if(Keyboard.isKeyPressed(.d)) {
            self.deltaRotation.y -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.z)) {
            self.deltaRotation.x -= deltaTime
        }
        
        if(Keyboard.isKeyPressed(.x)) {
            self.deltaRotation.x += deltaTime
        }
        
        rotation += deltaRotation
        
        var transform = matrix_identity_float4x4
        transform.rotate(angle: rotation.x, axis: X_AXIS)
        transform.rotate(angle: rotation.y, axis: Y_AXIS)
        transform.rotate(angle: rotation.z, axis: Z_AXIS)
        
        deltaPosition = (transform * _deltaPosition.simd4(w: 1)).xyz
        position += deltaPosition
        
        self.deltaRotationAboutOrigin.x = Mouse.getDWheelX()
        self.deltaRotationAboutOrigin.y = Mouse.getDWheelY()
    }
    
    
}
