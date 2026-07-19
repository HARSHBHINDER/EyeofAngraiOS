import SwiftUI

/// Video capture quality. Backed by AppStorage and read by CaptureController when
/// it configures the session, so changing it changes real behaviour.
enum VideoQuality: String, CaseIterable, Identifiable {
    case high = "High", medium = "Medium"
    var id: String { rawValue }
    var detail: String { self == .high ? "Best detail, larger files" : "Smaller files" }
}

struct SettingsView: View {
    @AppStorage("videoQuality") private var quality = VideoQuality.high.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section("Capture") {
                    Picker("Video quality", selection: $quality) {
                        ForEach(VideoQuality.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    Text(VideoQuality(rawValue: quality)?.detail ?? "")
                        .font(.footnote)
                        .foregroundStyle(Angra.textSecondary)
                }

                Section("Storage") {
                    LabeledContent("Captured", value: RecordingStore.format(RecordingStore.usedBytes))
                    LabeledContent("Free space", value: RecordingStore.format(RecordingStore.freeBytes))
                    Text("Recordings stay in this app's private storage. Nothing is uploaded or shared. Export them through the Files app under On My iPhone → EyeofAngra.")
                        .font(.footnote)
                        .foregroundStyle(Angra.textSecondary)
                }

                Section("About") {
                    NavigationLink("Safety & Legal") { SafetyLegalView() }
                    LabeledContent("Version", value: Bundle.main.version)
                    LabeledContent("Licence", value: "MIT")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Angra.background)
            .navigationTitle("Settings")
        }
    }
}

extension Bundle {
    var version: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
