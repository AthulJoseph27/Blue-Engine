import MetalKit
import MetalPerformanceShaders

enum ComputePipelineDescriptorTypes {
    case Basic
}

class ComputePipelineDescriptorLibrary {
    private static var computePipelineDescriptors: [ComputePipelineDescriptorTypes : ComputePipelineDescriptor] = [:]
    
    public static func initialize() {
        createComputePipelineDescriptor()
    }
    
    public static func createComputePipelineDescriptor() {
        computePipelineDescriptors.updateValue(Basic_ComputePipelineDescriptor(), forKey: .Basic)
    }
    
    public static func descriptor(_ computePipelineDescriptorTypes: ComputePipelineDescriptorTypes)->MTLComputePipelineDescriptor {
        return computePipelineDescriptors[computePipelineDescriptorTypes]!.computePipelineDescriptor
    }
}

protocol ComputePipelineDescriptor {
    var name: String { get }
    var computePipelineDescriptor: MTLComputePipelineDescriptor! { get }
}

public struct Basic_ComputePipelineDescriptor: ComputePipelineDescriptor {
    var name: String = "Baisc Compute Pipeline Descriptor"
    var computePipelineDescriptor: MTLComputePipelineDescriptor!
    
    init() {
        computePipelineDescriptor = MTLComputePipelineDescriptor()
        computePipelineDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = true
    }
}
