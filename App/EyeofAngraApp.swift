import SwiftUI

@main
struct EyeofAngraApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // A single dark product; it does not follow the system theme.
                .preferredColorScheme(.dark)
                .tint(Angra.gold)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            VideoRecorderView()
                .tabItem { Label("Video", systemImage: "video.fill") }
            AudioRecorderView()
                .tabItem { Label("Audio", systemImage: "waveform") }
            PhotoCaptureView()
                .tabItem { Label("Photo", systemImage: "camera.fill") }
            VaultView()
                .tabItem { Label("Vault", systemImage: "lock.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}
