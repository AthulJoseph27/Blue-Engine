import MetalKit

class GameObject: Node {
    var mesh: Mesh!
    var modelContants = ModelConstants()
    
    init(meshTypes: MeshTypes) {
        mesh = MeshLibrary.mesh(meshTypes)
    }
    
    override func update(deltaTime: Float) {
        self.rotation.z = -atan2(Mouse.getMouseViewportPosition().x - position.x, Mouse.getMouseViewportPosition().y - position.y)
        updateModelContants()
    }
    
    private func updateModelContants() {
        modelContants.modelMatrix = self.modelMatrix
    }
}

extension GameObject: Renderable {
    func doRender(_ renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.setRenderPipelineState(RenderPipelineStateLibrary.pipelineState(.Basic))
        renderCommandEncoder.setDepthStencilState(DepthStencilStateLibrary.depthStencileState(.Less))
        renderCommandEncoder.setVertexBytes(&modelContants, length: ModelConstants.stride, index: 2)
        mesh.drawPrimitives(renderCommandEncoder)
    }
}
