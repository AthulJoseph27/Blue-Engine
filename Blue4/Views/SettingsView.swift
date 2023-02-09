import SwiftUI

struct SettingsView: View {
    @StateObject private var model = SettingsViewModel.model
    
    var body: some View {
        TabView {
            ZStack {
                VStack {
                    Text("Ray Tracing").frame(alignment: .center).font(.title)
                    Spacer()
                    Text("Max bounce").frame(width: 100, alignment: .trailing)
                    HStack {
                        TextField("", value: $model.maxBounce, formatter: NumberFormatter())
                            .frame(width: 80)
                            .onChange(of: model.maxBounce, perform: model.updateMaxBounce)
                    }
                    Spacer()
                    Text("Vertex Shader").frame(alignment: .center).font(.title)
                    Spacer()
                }.frame(maxWidth: .infinity)
            }.tabItem {
                Text("View Port")
            }.frame(width: 600, alignment: .center)
            
            VStack {
                Text("Ray Tracing").frame(alignment: .center).font(.title)
                Spacer()
                Picker(selection: $model.currentScene, label: Text("scene").frame(width: 100, alignment: .trailing).padding(.trailing, 8)) {
                    ForEach(SettingsViewModel.scenes, id: \.self) { scene in
                        Text(scene.rawValue).tag(scene)
                    }.onChange(of: model.currentScene, perform: model.updateCurrentScene)
                    
                    Text("Vertex Shader").tag(RendererType.PhongShader)
                }
                Spacer()
                Text("Vertex Shader").frame(alignment: .center).font(.title)
                Spacer()
            }.tabItem {
                Text("Scene")
            }
        }
        .frame(width: 600, height: 600, alignment: .center)
        .transition(.opacity)
        
    }
}

//struct Preview_Settings: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
