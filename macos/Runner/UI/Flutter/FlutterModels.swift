import SwiftUI

enum RenderEngine: String {
    case aurora = "aurora"
    case velocity = "velocity"
}

class RenderImageModel {
    static var rendering = false
    var renderEngine = RenderEngine.velocity;
    var quality = RenderQuality.low;
    var resolution = SIMD2<Int>(x: 512, y: 512);
    var maxBounce = 1;
    var saveLocation = "Users/athuljoseph/Downloads/";
    var keepAlive = false;
    
    init(json: [String : Any]) {
        renderEngine = RenderEngine(rawValue: (json["renderEngine"] as? String) ?? "") ?? renderEngine
        quality = RenderQuality(rawValue: (json["quality"] as? String) ?? "") ?? quality
        
        let resolution = (json["resolution"] as? [String : Any]) ?? ["x" : 1080, "y": 720]
        self.resolution = SIMD2<Int>(resolution["x"] as! Int, resolution["y"] as! Int)
        
        maxBounce = (json["maxBounce"] as? Int) ?? maxBounce
        saveLocation = (json["saveLocation"] as? String) ?? saveLocation
        keepAlive = (json["keepAlive"] as? Bool) ?? keepAlive
        
        print(self)
    }
    
    func getRenderingSettings() -> RenderingSettings {
        if renderEngine == .velocity {
            return VertexShadingSettings()
        } else {
            return RayTracingSettings(maxBounce: maxBounce)
        }
    }
    
    func saveRenderImage() {
        guard let texture = RendererManager.getRenderedTexture() else { return }

        let image = texture.toCGImage()
        
        let bitmap = NSBitmapImageRep(cgImage: image!)
        let pngData = bitmap.representation(using: .png, properties: [:])
        
        do {
            if #available(macOS 13.0, *) {
                try pngData?.write(to: URL(filePath: "\(saveLocation)\(Int(Date().timeIntervalSince1970)).png"))
            } else {
                print("Couldn't save image, URL version error. min required macOS 13.0")
            }
        } catch {
            print("\(error)")
        }
    }
}
