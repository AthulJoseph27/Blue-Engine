import SwiftUI
import CoreData
import MetalKit


struct MetalView: NSViewControllerRepresentable {
    func makeNSViewController(context: Context) -> NSViewController {
        let storyboard = NSStoryboard(name: "Main", bundle: Bundle.main)
        let controller = storyboard.instantiateController(withIdentifier: "Content") as! NSViewController
        return controller
    }

    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {
        // Update the view and controller here
    }
}

var screen = NSScreen.main!.visibleFrame

struct ContentView: View {
    @StateObject var contentData = ContentViewModel()
    
    var body: some View {
            
            HStack {

                ZStack {
                    
                    switch contentData.selectedTab {
                        
                    case .RayTracing:
                        MetalView()
                            .edgesIgnoringSafeArea(.all)
                        
                    case .VertexShader:
                        Text("Vertex Shader")
                        
                    case .RenderImage:
                        Text("Render Image")
                        
                    case .RenderAnimation:
                        Color.green.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        
                    case .Settings:
                        Text("Settings")
                    }
                    
                    HStack {
                    
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                        
                            Button(action: {withAnimation{ contentData.showSideBar.toggle() }}, label: {
                                    
                                Image(systemName: "sidebar.right")
                                .font(.system(size: 16, weight: .semibold))
                                .padding(.vertical, 8)
                                    
                            })
                            .padding(.all, 8)
                            
                            Spacer()
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Sidebar(contentData: contentData)
                    .frame(width: contentData.showSideBar ? 100 : 0)
                    .opacity(contentData.showSideBar ? 1 : 0)
                
                
            }
            .ignoresSafeArea(.all, edges: .all)
            
        }
    
}
