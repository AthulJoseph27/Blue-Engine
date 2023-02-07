import SwiftUI

struct RenderPopUpWindow: View {
    let metalView = MetalView(.StaticRT)
    
    var body: some View {
        metalView
            .edgesIgnoringSafeArea(.all)
    }
}
