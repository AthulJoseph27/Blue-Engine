import MetalKit
import MetalPerformanceShaders

enum ComputePipelineDescriptorTypes {
    case RayTracing
}

class ComputePipelineDescriptorLibrary {
    private static var computePipelineDescriptors: [ComputePipelineDescriptorTypes : ComputePipelineDescriptor] = [:]
    
    public static func initialize() {
        createComputePipelineDescriptor()
    }
    
    public static func createComputePipelineDescriptor() {
        computePipelineDescriptors.updateValue(RayTracing_ComputePipelineDescriptor(), forKey: .RayTracing)
    }
    
    public static func descriptor(_ computePipelineDescriptorTypes: ComputePipelineDescriptorTypes)->MTLComputePipelineDescriptor {
        return computePipelineDescriptors[computePipelineDescriptorTypes]!.computePipelineDescriptor
    }
}

protocol ComputePipelineDescriptor {
    var name: String { get }
    var computePipelineDescriptor: MTLComputePipelineDescriptor! { get }
}

public struct RayTracing_ComputePipelineDescriptor: ComputePipelineDescriptor {
    var name: String = "Basic Compute Pipeline Descriptor"
    var computePipelineDescriptor: MTLComputePipelineDescriptor!
    
    init() {
        computePipelineDescriptor = MTLComputePipelineDescriptor()
        computePipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
    }
}
