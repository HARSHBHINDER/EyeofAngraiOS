import SwiftUI
import UIKit

@main
struct EyeofAngraApp: App {
    init() { Self.applyPremiumChrome() }

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
    @State private var tab = 0

    var body: some View {
        TabView(selection: $tab) {
            VideoRecorderView()
                .tabItem { Label("Video", systemImage: "video.fill") }.tag(0)
            AudioRecorderView()
                .tabItem { Label("Audio", systemImage: "waveform") }.tag(1)
            PhotoCaptureView()
                .tabItem { Label("Photo", systemImage: "camera.fill") }.tag(2)
            VaultView()
                .tabItem { Label("Vault", systemImage: "lock.fill") }.tag(3)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }.tag(4)
        }
        // Widget deeplinks land here. Camera needs the app foregrounded, so the
        // widget can only open us into the tab and auto-arm the capture.
        .onOpenURL { url in
            switch url.host {
            case "video":
                tab = 0
                CaptureController.shared.pendingAutoStart = true
                CaptureController.shared.start(mode: .video)
            case "audio":
                tab = 1
                AudioRecorderController.shared.start()
            case "photo":
                tab = 2
            default:
                break
            }
        }
    }
}

private extension EyeofAngraApp {
    static let bone = UIColor(red: 0.96, green: 0.949, blue: 0.925, alpha: 1)
    static let gold = UIColor(red: 0.831, green: 0.686, blue: 0.216, alpha: 1)

    /// Glass tab bar with a gold hairline, and serif nav titles — the premium chrome.
    static func applyPremiumChrome() {
        let tab = UITabBarAppearance()
        tab.configureWithDefaultBackground()
        tab.backgroundColor = UIColor(white: 0.045, alpha: 0.82)
        tab.shadowColor = gold.withAlphaComponent(0.28)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab

        let nav = UINavigationBarAppearance()
        nav.configureWithTransparentBackground()
        if let d = UIFont.systemFont(ofSize: 34, weight: .medium).fontDescriptor.withDesign(.serif) {
            nav.largeTitleTextAttributes = [.font: UIFont(descriptor: d, size: 34), .foregroundColor: bone]
        }
        if let d = UIFont.systemFont(ofSize: 17, weight: .semibold).fontDescriptor.withDesign(.serif) {
            nav.titleTextAttributes = [.font: UIFont(descriptor: d, size: 17), .foregroundColor: bone]
        }
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }
}
