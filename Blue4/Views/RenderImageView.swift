import SwiftUI

struct RenderImage: View {
    @StateObject private var model = RenderImageViewModel()

    var body: some View {
        Form {
            
            VStack() {
                Picker(selection: $model.renderer, label: Text("Renderer").frame(width: 100, alignment: .trailing).padding(.trailing, 8)) {
                    Text("Ray Tracing").tag(RendererType.RayTracing)
                    Text("Vertex Shader").tag(RendererType.VertexShader)
                }
                
                Picker(selection: $model.quality, label: Text("Quality").frame(width: 100, alignment: .trailing).padding(.trailing, 8)) {
                    Text("High").tag(RenderQuality.high)
                    Text("Medium").tag(RenderQuality.medium)
                    Text("Low").tag(RenderQuality.low)
                }
                
                HStack {
                    Text("Resolution").frame(width: 100, alignment: .trailing)
                    HStack {
                        TextField("", value: $model.resolution.x, formatter: NumberFormatter())
                            .frame(width: 80)
                        Text("x")
                        TextField("", value: $model.resolution.y, formatter: NumberFormatter())
                            .frame(width: 80)
                        Spacer()
                    }
                    .frame(width: 492)
                }
                .frame(maxWidth: .infinity)
                

                HStack {
                    Text("Max bounce").frame(width: 100, alignment: .trailing)
                    HStack {
                        TextField("", value: $model.maxBounce, formatter: NumberFormatter())
                            .frame(width: 80)
                            .disabled(model.renderer != .RayTracing)
                        Spacer()
                    }
                    .frame(width: 492)
                }
                .frame(maxWidth: .infinity)

                
                HStack {
                    Text("Save Location").frame(width: 100, alignment: .trailing)
                    TextField("", text: $model.saveLocation)
                }
                Button(action: {
                    if model.rendering {
                        return
                    }
                    
                    model.rendering = true
                    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: model.resolution.x, height: model.resolution.y),
                                          styleMask: [.titled, .closable],
                                                      backing: .buffered,
                                                      defer: false)
                    window.center()
                    window.contentView = NSHostingView(rootView: RenderPopUpWindow())

                    let windowController = NSWindowController(window: window)
                    windowController.showWindow(nil)
                    RendererManager.setRenderMode {
                        model.saveRenderImage()
                        model.rendering = false
                        window.close()
                    }
//                        model.saveRenderImage()
                }) {
                    Text("Render")
                }
            }
        }
        .frame(width: 600, alignment: .center)
        
    }
}
