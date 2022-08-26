import MetalKit

enum ComputePipelineStateTypes {
    case TraceRay
    case Transform
}

class ComputePipelineStateLibrary {
    private static var computePipelineStates: [ComputePipelineStateTypes : ComputePipelineState] = [:]

    public static func initialize() {
        createComputePipelineState()
    }

    public static func createComputePipelineState() {
        computePipelineStates.updateValue(TraceRay_ComputePipelineState(), forKey: .TraceRay)
        computePipelineStates.updateValue(Transform_ComputePipelineState(), forKey: .Transform)
    }

    public static func pipelineState(_ computePipelineStateTypes: ComputePipelineStateTypes)->ComputePipelineState {
        return computePipelineStates[computePipelineStateTypes]!
    }
}

protocol ComputePipelineState {
    var name: String { get }
    var computePipelineState: MTLComputePipelineState! { get }
}


public struct TraceRay_ComputePipelineState: ComputePipelineState {
    var name: String = "Ray Tracing Compute Pipeline State"
    var computePipelineState: MTLComputePipelineState!
    
    init() {
        do{
            ComputePipelineDescriptorLibrary.descriptor(.Basic).computeFunction = Engine.defaultLibrary.makeFunction(name: "ray_tracing_kernel")
            computePipelineState = try Engine.device.makeComputePipelineState(descriptor: ComputePipelineDescriptorLibrary.descriptor(.Basic), options: [], reflection: nil)
        }catch let error as NSError{
            print("ERROR::CREATE::COMPUTE_PIPELINE_STATE::__\(name)__::\(error)")
            return;
        }
    }
}

public struct Transform_ComputePipelineState: ComputePipelineState {
    var name: String = "Object Tranform Compute Pipeline State"
    var computePipelineState: MTLComputePipelineState!
    
    init() {
        do{
            ComputePipelineDescriptorLibrary.descriptor(.Basic).computeFunction = Engine.defaultLibrary.makeFunction(name: "transform_tracing_kernel")
            computePipelineState = try Engine.device.makeComputePipelineState(descriptor: ComputePipelineDescriptorLibrary.descriptor(.Basic), options: [], reflection: nil)
        }catch let error as NSError{
            print("ERROR::CREATE::COMPUTE_PIPELINE_STATE::__\(name)__::\(error)")
            return;
        }
    }
}

