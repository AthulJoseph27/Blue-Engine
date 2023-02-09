import SwiftUI

class RenderImageViewModel: ObservableObject {
    @Published var renderer: RendererType = .StaticRT
    @Published var quality: RenderQuality = .medium
    @Published var resolution = SIMD2<Int>(1080, 720)
    @Published var maxBounce = 6
    @Published var saveLocation = "/Users/athuljoseph/Downloads/"
    @Published var rendering = false
    
    func getRenderingSettings() -> RenderingSettings {
        if renderer == .PhongShader {
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
            try pngData?.write(to: URL(filePath: "\(saveLocation)\(Int(Date().timeIntervalSince1970)).png"))
        } catch {
            print("\(error)")
        }
    }
    
}
 
