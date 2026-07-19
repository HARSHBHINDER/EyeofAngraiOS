import SwiftUI

struct SafetyLegalView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    section("What this app records",
                            "Video with sound (Video tab), audio only (Audio tab), and still photos (Photos tab). Recording starts only when you tap a record button — never automatically.")
                    section("Always visible",
                            "A red indicator is shown on screen whenever recording is active. This app is not a hidden camera and must not be used as one. iOS also shows its own system microphone and camera indicators.")
                    section("Your data stays on this device",
                            "Recordings are saved only to this app's Documents folder on your phone. Nothing is uploaded, synced, or shared automatically. You can export files through the Files app (On My iPhone > EyeofAngra).")
                    section("Your legal responsibility",
                            "Laws on recording conversations, filming people, and using recordings as evidence differ by country and state (for example one-party vs. all-party consent). You are responsible for complying with the laws that apply to you.")
                    section("Intended use",
                            "EyeofAngra is meant for emergency documentation: protecting yourself and preserving evidence if you are attacked, harassed, or falsely accused. It is not a surveillance tool.")
                }
                .padding()
            }
            .navigationTitle("Safety & Legal")
        }
    }

    private func section(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text)
        }
    }
}
