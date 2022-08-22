import MetalKit

enum ComputePipelineStateTypes {
    case Basic
}

class ComputePipelineStateLibrary {
    private static var computePipelineStates: [ComputePipelineStateTypes : ComputePipelineState] = [:]

    public static func initialize() {
        createComputePipelineState()
    }

    public static func createComputePipelineState() {
        computePipelineStates.updateValue(ComputePipelineState(), forKey: .Basic)
    }

    public static func pipelineState(_ computePipelineStateTypes: ComputePipelineStateTypes)->ComputePipelineState {
        return computePipelineStates[computePipelineStateTypes]!
    }
}


public struct ComputePipelineState {
    var name: String = "Baisc Compute Pipeline State"
    var rayPipelineState: MTLComputePipelineState!
//    var shadePipelineState: MTLComputePipelineState!
//    var shadowPipelineState: MTLComputePipelineState!
//    var accumulatePipelineState: MTLComputePipelineState!
    
    init() {
        do{
            ComputePipelineDescriptorLibrary.descriptor(.Basic).computeFunction = Engine.defaultLibrary.makeFunction(name: "ray_tracing_kernel")
            rayPipelineState = try Engine.device.makeComputePipelineState(descriptor: ComputePipelineDescriptorLibrary.descriptor(.Basic), options: [], reflection: nil)
        }catch let error as NSError{
            print("ERROR::CREATE::COMPUTE_PIPELINE_STATE::__\(name)__::\(error)")
            return;
        }
        
//        do{
//            ComputePipelineDescriptorLibrary.descriptor(.Basic).computeFunction = Engine.defaultLibrary.makeFunction(name: "shadeKernel")
//            shadePipelineState = try Engine.device.makeComputePipelineState(descriptor: ComputePipelineDescriptorLibrary.descriptor(.Basic), options: [], reflection: nil)
//        }catch let error as NSError{
//            print("ERROR::CREATE::COMPUTE_PIPELINE_STATE::__\(name)__::\(error)")
//            return;
//        }
//
//        do{
//            ComputePipelineDescriptorLibrary.descriptor(.Basic).computeFunction = Engine.defaultLibrary.makeFunction(name: "shadowKernel")
//            shadowPipelineState = try Engine.device.makeComputePipelineState(descriptor: ComputePipelineDescriptorLibrary.descriptor(.Basic), options: [], reflection: nil)
//        }catch let error as NSError{
//            print("ERROR::CREATE::COMPUTE_PIPELINE_STATE::__\(name)__::\(error)")
//            return;
//        }
//
//        do{
//            ComputePipelineDescriptorLibrary.descriptor(.Basic).computeFunction = Engine.defaultLibrary.makeFunction(name: "accumulateKernel")
//            accumulatePipelineState = try Engine.device.makeComputePipelineState(descriptor: ComputePipelineDescriptorLibrary.descriptor(.Basic), options: [], reflection: nil)
//        }catch let error as NSError{
//            print("ERROR::CREATE::COMPUTE_PIPELINE_STATE::__\(name)__::\(error)")
//            return;
//        }
        
    }
}

