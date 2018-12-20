//
//  MTLRenderView.swift
//  ReactiveMetal
//
//  Created by s.kananat on 2018/12/06.
//  Copyright © 2018 s.kananat. All rights reserved.
//

import MetalKit
import ReactiveSwift
import ReactiveCocoa
import SnapKit

// MARK: Main
/// View for rendering image output using metal enabled device
public final class RenderView: UIView {
    
    public var sourceCount = 0
    
    let pipelineState: MTLRenderPipelineState
    
    let vertexFunction: VertexFunction = .default
    let fragmentFunction: FragmentFunction = .default

    /// Metal view
    private lazy var metalView: MTKView = {
        let view = MTKView(frame: self.frame)
        
        view.device = MTL.default.device
        view.delegate = self
        
        return view
    }()
    
    /// Initializes and returns a newly allocated view object with the specified frame rectangle
    public init!(_ frame: CGRect = .zero) {
        
        guard MTL.default != nil else { return nil }

        self.pipelineState = MTL.default.makePipelineState(vertexFunction: vertexFunction, fragmentFunction: fragmentFunction)!
        
        super.init(frame: frame)

        self.addSubview(self.metalView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// MARK: Inheritance
extension RenderView {
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.metalView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

/// MARK: Protocol
extension RenderView: Renderer { }

extension RenderView: MTKViewDelegate {
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
    
    public func draw(in view: MTKView) { self.render(in: view) }
}
