import SwiftUI

struct SafetyLegalView: View {
    // Pushed from Settings, so it does not carry its own NavigationStack.
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                section("What this app records",
                        "Video with sound, audio only, and still photos. Recording starts only when you tap a record button — never automatically.")
                section("Always visible",
                        "A red indicator is shown on screen whenever recording is active. This app is not a hidden camera and must not be used as one. iOS also shows its own system microphone and camera indicators.")
                section("Your data stays on this device",
                        "Recordings are saved only to this app's storage on your phone. Nothing is uploaded, synced, or shared automatically. You can export files through the Files app (On My iPhone → EyeofAngra).")
                section("Your legal responsibility",
                        "Laws on recording conversations, filming people, and using recordings as evidence differ by country and state (for example one-party vs. all-party consent). You are responsible for complying with the laws that apply to you.")
                section("Intended use",
                        "EyeofAngra is meant for emergency documentation: protecting yourself and preserving evidence if you are attacked, harassed, or falsely accused. It is not a surveillance tool.")
                section("Limitations",
                        "This app cannot guarantee your safety, the recovery of an interrupted recording, or that a recording will be accepted as evidence anywhere.")
            }
            .padding()
        }
        .background(Angra.background)
        .navigationTitle("Safety & Legal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline).foregroundStyle(Angra.gold)
            Text(text).foregroundStyle(Angra.textSecondary)
        }
    }
}
