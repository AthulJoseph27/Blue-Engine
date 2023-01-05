import MetalKit

class Light: Solid {
    var lightData: LightData!;
    
    init(meshType: MeshTypes, lightData: LightData = LightData()) {
        super.init(meshType)
        self.lightData = lightData
    }
    
    
}
