import SwiftUI
import CoreData
import MetalKit

var screen = NSScreen.main!.visibleFrame
var gameViewController: NSViewController!
var gameStoryboard: NSStoryboard!

struct ContentView: View {
    @StateObject var contentData = ContentViewModel()
    
    let RTView = MetalView(.StaticRT)
    let PSView = MetalView(.VertexShader)
    
    var body: some View {

                ZStack {
                    
                    switch contentData.selectedTab {
                        
                    case .RayTracing:
                        RTView
                            .edgesIgnoringSafeArea(.all)
                        
                    case .VertexShader:
                        PSView
                            .edgesIgnoringSafeArea(.all)
                        
                    case .RenderImage:
                        RenderImage()
                        
                    case .RenderAnimation:
                        Color.green.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        
                    case .Settings:
                        SettingsView()
                    }
                    
                    HStack() {
                        Spacer()
                        
                        Sidebar(contentData: contentData)
                            .frame(width: 100)
                            .offset(x: contentData.showSideBar ? 0 : 120)
                        
                    }
                    
                    HStack {
                    
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                        
                            Button(action: {withAnimation{ contentData.showSideBar.toggle() }}, label: {
                                    
                                Image(systemName: "sidebar.right")
                                .font(.system(size: 16, weight: .semibold))
                                    
                            })
                            .padding(.all, 12)
                            .buttonStyle(PlainButtonStyle())
                            .opacity((contentData.showDrawerButton || contentData.showSideBar) ? 1 : 0)
                            .onHover{ hover in
                                withAnimation {
                                    contentData.showDrawerButton = hover
                                }
                            }
                            
                            Spacer()
                        }
                    }
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all, edges: .all)
                .onChange(of: contentData.selectedTab) { value in
                    if contentData.selectedTab != .RayTracing && contentData.selectedTab != .VertexShader {
                        RendererManager.pauseAllRenderingLoop()
                    } else {
                        RendererManager.resumeRenderingLoop()
                    }
                    
                    if contentData.selectedTab == .RayTracing {
                        RendererManager.updateViewPort(viewPortType: .StaticRT)
                    } else if contentData.selectedTab == .VertexShader{
                        RendererManager.updateViewPort(viewPortType: .VertexShader)
                    }
                }
                
            }
    
}
