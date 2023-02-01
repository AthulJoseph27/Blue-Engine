import SwiftUI

struct RenderPopUpWindow: View {
    let metalView = RendererView.metalView
    
    var body: some View {
        metalView
            .edgesIgnoringSafeArea(.all)
    }
}
