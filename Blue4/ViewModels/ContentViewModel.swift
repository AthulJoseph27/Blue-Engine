import SwiftUI

enum ViewTab {
    case RayTracing
    case VertexShader
    case RenderImage
    case RenderAnimation
    case Settings
}

class ContentViewModel: ObservableObject {
    @Published var selectedTab = ViewTab.RayTracing
    @Published var showDrawerButton = false
    @Published var showSideBar = true
}
