//
//  BlurView.swift
//  Blue4
//
//  Created by Athul Joseph on 27/01/23.
//

import SwiftUI

struct BlurView: NSViewRepresentable {
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        
        return view
    }
    
    func updateNSView(_ nsView: NSViewType, context: Context) {
    }
    
    
}
