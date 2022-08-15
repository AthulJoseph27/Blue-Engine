import MetalKit

enum DepthStencilStateTypes {
    case Less
}

class DepthStencilStateLibrary {
    private static var _depthStencilStates: [DepthStencilStateTypes : DepthStencilState] = [:]
    
    public static func initialize() {
        createDefaultDepthStencileState()
    }
    
    private static func createDefaultDepthStencileState() {
        _depthStencilStates.updateValue(Less_DepthStencilState(), forKey: .Less)
    }
    
    public static func depthStencileState(_ depthStencileStateType: DepthStencilStateTypes)->MTLDepthStencilState {
        return _depthStencilStates[depthStencileStateType]!.depthStencilState
    }
}

protocol DepthStencilState {
    var depthStencilState: MTLDepthStencilState! { get }
}

class Less_DepthStencilState : DepthStencilState {
    var depthStencilState: MTLDepthStencilState!
    
    init() {
        let depthStencileDescriptor = MTLDepthStencilDescriptor()
        depthStencileDescriptor.isDepthWriteEnabled = true
        depthStencileDescriptor.depthCompareFunction = .less
        depthStencilState = Engine.Device.makeDepthStencilState(descriptor: depthStencileDescriptor)
    }
}
