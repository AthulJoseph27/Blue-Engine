import MetalKit

enum VertexShaderTypes {
    case Basic
    case RayTracing
}

enum FragmentShaderTypes {
    case Basic
    case RayTracing
}

class ShaderLibrary {
    private static var vertexShaders: [VertexShaderTypes: Shader] = [:]
    private static var fragmentShaders: [FragmentShaderTypes: Shader] = [:]
    
    public static func initialize() {
        createDefaultShaders()
    }
    
    public static func createDefaultShaders() {
        //Vertex Shaders
        vertexShaders.updateValue(Basic_VertexShader(), forKey: .Basic)
        vertexShaders.updateValue(RayTracing_VertexShader(), forKey: .RayTracing)
        
        //Fragment Shaders
        fragmentShaders.updateValue(Basic_FragmentShader(), forKey: .Basic)
        fragmentShaders.updateValue(RayTracing_FragmentShader(), forKey: .RayTracing)
    }
    
    public static func Vertex(_ vertexShaderType: VertexShaderTypes)->MTLFunction {
        return vertexShaders[vertexShaderType]!.function
    }
    
    public static func Fragment(_ fragmentShaderType: FragmentShaderTypes)->MTLFunction {
        return fragmentShaders[fragmentShaderType]!.function
    }
    
}

protocol Shader {
    var name: String { get }
    var functionName: String { get }
    var function: MTLFunction! { get }
}

public struct Basic_VertexShader: Shader {
    public var name: String = "Basic Vertex Shader"
    public var functionName: String = "basic_vertex_shader"
    public var function: MTLFunction!
    init() {
        function = Engine.defaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct RayTracing_VertexShader: Shader {
    public var name: String = "RayTracing Vertex Shader"
    public var functionName: String = "copy_vertex"
    public var function: MTLFunction!
    init() {
        function = Engine.defaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct Basic_FragmentShader: Shader {
    public var name: String = "Basic Fragment Shader"
    public var functionName: String = "basic_fragment_shader"
    public var function: MTLFunction!
    init() {
        function = Engine.defaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}

public struct RayTracing_FragmentShader: Shader {
    public var name: String = "RayTracing Fragment Shader"
    public var functionName: String = "copy_fragment"
    public var function: MTLFunction!
    init() {
        function = Engine.defaultLibrary.makeFunction(name: functionName)
        function?.label = name
    }
}
