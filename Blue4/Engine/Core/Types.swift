import simd
import CoreImage
import MetalPerformanceShaders

protocol sizeable {}
extension sizeable {
    static var size: Int{
        return MemoryLayout<Self>.size
    }
    
    static var stride: Int {
        return MemoryLayout<Self>.stride
    }
    
    static func size(_ count: Int)->Int {
        return MemoryLayout<Self>.size * count
    }
    
    static func stride(_ count: Int)->Int {
        return MemoryLayout<Self>.stride * count
    }
}

extension uint:  sizeable {}
extension Int32: sizeable {}
extension Float: sizeable {}
extension SIMD2: sizeable {}
extension SIMD3: sizeable {}
extension SIMD4: sizeable {}
extension matrix_float4x4: sizeable {}
extension MPSIntersectionDistancePrimitiveIndexCoordinates: sizeable {}

struct Vertex: sizeable{
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var uvCoordinate: SIMD2<Float>
}

struct VertexIn: sizeable{
    var position: SIMD3<Float>
    var uvCoordinate: SIMD2<Float>
    var normal: SIMD3<Float>
    var tangent: SIMD3<Float>
    var bitangent: SIMD3<Float>
}

struct VertexOut: sizeable{
    var position: SIMD3<Float>
    var uvCoordinate: SIMD2<Float>
    var normal: SIMD3<Float>
    var tangent: SIMD3<Float>
    var bitangent: SIMD3<Float>
}

struct PrimitiveData: sizeable {
    var texture: MTLTexture?
}

struct AreaLight: sizeable {
    var position: SIMD3<Float>
    var forward: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
    var color: SIMD3<Float>
}

struct LightData: sizeable {
    var position = SIMD3<Float>(repeating: 0)
    var color = SIMD3<Float>(repeating: 1)
    
    var brightness: Float = 1.0
    var ambientIntensity: Float = 1.0
    var diffuseIntensity: Float = 1.0
    var specularIntensity: Float = 1.0
    
}

struct Material: sizeable {
    var color = SIMD4<Float>(0.6, 0.6, 0.6, 1.0)
    var isLit: Bool = true
    
    var ambient = SIMD3<Float>(0.1, 0.1, 0.1)
    var diffuse = SIMD3<Float>(1, 1, 1)
    var specular = SIMD3<Float>(1, 1, 1)
    var emissive = SIMD3<Float>(1, 1, 1)
    var shininess: Float = 2.0
    var opacity: Float = 1.0
    var opticalDensity: Float = 1.0
    var roughness: Float = 1.0
    var isTextureEnabled: Bool = true
    var isNormalMapEnabled: Bool = true
    var isMetallicMapEnabled: Bool = true
    var isRoughnessMapEnabled: Bool = true
}

struct RotationMatrix: sizeable {
    var rotationMatrix: matrix_float4x4
}

struct CameraOut: sizeable {
    var position: SIMD3<Float>
    var forward: SIMD3<Float>
    var right: SIMD3<Float>
    var up: SIMD3<Float>
//    var rotationMatrix: matrix_float4x4
}

struct ModelConstants: sizeable {
    var modelMatrix = matrix_identity_float4x4
}

struct SceneConstants: sizeable {
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    var cameraPosition = SIMD3<Float>(repeating: 0)
}

struct Textures: sizeable {
    var baseColor: MTLTexture?
    var normalMap: MTLTexture?
    var metallic:  MTLTexture?
    var roughness: MTLTexture?
}

struct VertexIndex: sizeable {
    var index: UInt32
    var submeshId: UInt32
}

class Masks {
    public static let FACE_MASK_NONE: uint = 0
    public static let FACE_MASK_NEGATIVE_X: uint = (1 << 0)
    public static let FACE_MASK_POSITIVE_X: uint = (1 << 1)
    public static let FACE_MASK_NEGATIVE_Y: uint = (1 << 2)
    public static let FACE_MASK_POSITIVE_Y: uint = (1 << 3)
    public static let FACE_MASK_NEGATIVE_Z: uint = (1 << 4)
    public static let FACE_MASK_POSITIVE_Z: uint = (1 << 5)
    public static let FACE_MASK_ALL: uint = ((1 << 6) - 1)
    
    public static let TRIANGLE_MASK_GEOMETRY: uint = 1
    public static let TRIANGLE_MASK_LIGHT: uint = 2
}

struct RTRenderOptions {
    var intersectionStride = MemoryLayout<MPSIntersectionDistancePrimitiveIndexInstanceIndexCoordinates>.size
    var intersectionDataType = MPSIntersectionDataType.distancePrimitiveIndexInstanceIndexCoordinates
    var maxFramesInFlight = 3
    var alignedUniformsSize = (MemoryLayout<Uniforms>.stride + 255) & ~255
    var rayStride = 48
    var rayMaskOptions = MPSRayMaskOptions.primitive
}

struct PSRenderOptions {
    
}

extension MTLTexture {
    func toCGImage() -> CGImage? {
        guard let ciImage = CIImage(mtlTexture: self, options: nil) else { return nil }
        let flippedImage = ciImage.oriented(.left).oriented(.left).oriented(.upMirrored)
        let context = CIContext(options: nil)
        return context.createCGImage(flippedImage, from: CGRect(x: 0, y: 0, width: width, height: height))
     }
}

protocol RenderingSettings {
    
}

struct RayTracingSettings: RenderingSettings {
    var maxBounce: Int
}

struct VertexShadingSettings: RenderingSettings {
    
}

enum RenderMode {
    case display
    case render
}

enum RenderQuality {
    case low
    case medium
    case high
}

enum RendererType : CaseIterable {
    case StaticRT
    case DynamicRT
    case PhongShader
}

enum GameScenes: String {
    case Sandbox = "Sandbox"
    case TestScene = "Test Scene"
}

enum RenderViewPortType : String, CaseIterable {
    case StaticRT
    case DynamicRT
    case PhongShader
    case Render
}
