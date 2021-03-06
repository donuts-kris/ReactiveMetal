//
//  Renderer.swift
//  ReactiveMetal
//
//  Created by s.kananat on 2018/12/07.
//  Copyright © 2018 s.kananat. All rights reserved.
//

import MetalKit
import ReactiveSwift

// MARK: Main
/// Protocol for image target using metal enabled device
protocol Renderer: ImageTarget {

    /// Render pipeline state
    var pipelineState: MTLRenderPipelineState { get }

    /// Vertex function
    var vertexFunction: VertexFunction { get }
    
    /// Fragment function
    var fragmentFunction: FragmentFunction { get }
    
    /// Encode with encoder (optional)
    func encode(with encoder: MTLRenderCommandEncoder)
}

// MARK: Public
extension Renderer {
    
    public func encode(with encoder: MTLRenderCommandEncoder) {
        
        // Vertex buffer
        encoder.setVertexBuffer(self.vertexFunction.vertexBuffer, offset: 0, index: 0)
        
        // Fragment textures
        for (index, texture) in (self.fragmentFunction.textures.map { $0.value }.enumerated()) { encoder.setFragmentTexture(texture, index: index) }
        
        // Fragment buffers
        for (index, buffer) in (self.fragmentFunction.buffers.map { $0.value }.enumerated()) { encoder.setFragmentBuffer(buffer, offset: 0, index: index) }
        
        // Draw indexed vertices
        encoder.drawIndexedPrimitives(type: .triangle, indexCount: self.vertexFunction.indexCount, indexType: .uint16, indexBuffer: self.vertexFunction.indexBuffer, indexBufferOffset: 0)
    }
    
    public var maxSourceCount: Int { return self.fragmentFunction.maxSourceCount }
    
    public func input(at index: Int) -> BindingTarget<MTLTexture?> { return self.fragmentFunction.textures[index].bindingTarget }
}

// MARK: Internal
internal extension Renderer {
    
    /// Renders to texture
    func render(completion: @escaping (MTLTexture) -> ()) {
        let output = MTL.default.makeEmptyTexture()!
        
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = output
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(1, 0, 0, 1)
        descriptor.colorAttachments[0].storeAction = .store
        descriptor.colorAttachments[0].loadAction = .clear
        
        self.render(descriptor: descriptor) { commandBuffer in
            commandBuffer.addCompletedHandler { _ in completion(output) }
        }
    }
    
    /// Renders in `MTKView`
    func render(in view: MTKView) {
        guard let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor
            else { return }
        
        self.render(descriptor: descriptor) { commandBuffer in
            commandBuffer.present(drawable)
        }
    }
    
    /// Received new texture (reactive)
    var textureReceived: Signal<(index: Int, element: MTLTexture?), Never> {
        return Signal.merge(self.fragmentFunction.textures.enumerated().map { index, element in element.map { value in (index: index, element: value) }.signal }
        )
    }
}

// MARK: Private
private extension Renderer {
    
    /// Main implementation of `render`
    func render(descriptor: MTLRenderPassDescriptor, completion: @escaping (MTLCommandBuffer) -> ()) {
        
        guard self.fragmentFunction.isRenderable else { return }
        
        let commandBuffer = MTL.default.commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        
        // Render pipeline state
        commandEncoder.setRenderPipelineState(self.pipelineState)
        
        // Begin encoding
        self.encode(with: commandEncoder)
        
        // End encoding
        commandEncoder.endEncoding()
        
        // Custom action
        completion(commandBuffer)
        
        commandBuffer.commit()
    }
}
