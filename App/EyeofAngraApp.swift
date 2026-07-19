import SwiftUI

@main
struct EyeofAngraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            VideoRecorderView()
                .tabItem { Label("Video", systemImage: "video.fill") }
            AudioRecorderView()
                .tabItem { Label("Audio", systemImage: "mic.fill") }
            PhotoCaptureView()
                .tabItem { Label("Photos", systemImage: "camera.fill") }
            SafetyLegalView()
                .tabItem { Label("Info", systemImage: "info.circle") }
        }
    }
}
