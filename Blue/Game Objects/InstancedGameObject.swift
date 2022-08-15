import MetalKit

class InstancedGameObject: Node {
    private var _mesh: Mesh!
    internal var _nodes: [Node] = []
    private var _modelConstantBuffer: MTLBuffer!
    
    private var _modelConstants: [ModelConstants] = []
    
    init(meshType: MeshTypes, instanceCount: Int) {
        super.init()
        self._mesh = MeshLibrary.mesh(meshType)
        self._mesh.setInstanceCount(instanceCount)
        self.generateInstances(instanceCount)
        self.createBuffers(instanceCount)
    }
    
    func generateInstances(_ instanceCount: Int) {
        for _ in 0..<instanceCount {
            _nodes.append(Node())
        }
    }
    
    func createBuffers(_ instanceCount: Int) {
        _modelConstantBuffer = Engine.Device.makeBuffer(length: ModelConstants.stride(instanceCount), options: [])
    }
    
    private func updateModelConstantsBuffer() {
        var pointer = _modelConstantBuffer.contents().bindMemory(to: ModelConstants.self, capacity: _modelConstants.count)
        
        for node in _nodes {
            pointer.pointee.modelMatrix = node.modelMatrix
            pointer = pointer.advanced(by: 1)
        }
    }
    
    override func update(deltaTime: Float) {
        updateModelConstantsBuffer()
        super.update(deltaTime: deltaTime)
    }
}

extension InstancedGameObject: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStateLibrary.pipelineState(.Instanced))
        renderCommandEncoder.setDepthStencilState(DepthStencilStateLibrary.depthStencileState(.Less))
        renderCommandEncoder.setVertexBuffer(_modelConstantBuffer, offset: 0, index: 2)
        _mesh.drawPrimitives(renderCommandEncoder)
    }
    
}
