import MetalKit
import simd

enum SkyboxTypes {
    case Sky
    case WhiteMarble
    case Beach
    case City
    case NightCity
    case Pond
    case Jungle
    case Sunset
}

class Skyboxibrary {
    private static var skyboxes: [SkyboxTypes : MTLTexture] = [:]
    
    public static func initialize() {
        loadSkyboxes()
    }
    
    private static func loadSkyboxes() {
        skyboxes.updateValue(loadTextureFromBundle(textureName: "Beach", ext: "jpeg"), forKey: .Beach)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "City", ext: "jpeg"), forKey: .City)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "Jungle", ext: "jpg"), forKey: .Jungle)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "NightCity", ext: "jpg"), forKey: .NightCity)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "Pond", ext: "jpg"), forKey: .Pond)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "Sky", ext: "jpg"), forKey: .Sky)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "Sunset", ext: "jpg"), forKey: .Sunset)
        skyboxes.updateValue(loadTextureFromBundle(textureName: "WhiteMarble", ext: "jpg"), forKey: .WhiteMarble)
    }
    
    private static func loadTextureFromBundle(textureName: String, ext: String)->MTLTexture {
        var result: MTLTexture!
        
        if let url = Bundle.main.url(forResource: textureName, withExtension: ext) {
            let textureLoader = Engine.textureLoader
            let options: [MTKTextureLoader.Option : Any] = [MTKTextureLoader.Option.origin: MTKTextureLoader.Origin.topLeft]
            
            do {
                result = try textureLoader?.newTexture(URL: url, options:  options)
                result.label = textureName
            } catch let error as NSError {
                print("ERROR::CREATING::TEXTURE::__\(textureName)__::\(error)")
            }
            
        } else {
            print("ERROR::CREATING::TEXTURE::__\(textureName) doesn't exist")
        }
        
        return result
    }
    
    public static func skybox(_ skyboxType: SkyboxTypes)->MTLTexture{
        return skyboxes[skyboxType]!
    }
}