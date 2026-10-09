import SwiftUI

/// Video capture quality. Backed by AppStorage and read by CaptureController when
/// it configures the session, so changing it changes real behaviour.
enum VideoQuality: String, CaseIterable, Identifiable {
    case uhd = "4K", high = "1080p", medium = "720p"
    var id: String { rawValue }
    var detail: String {
        switch self {
        case .uhd: "Sharpest, largest files (newer iPhones only)"
        case .high: "Full HD — the balanced default"
        case .medium: "Smaller files, longer recordings"
        }
    }
}

struct SettingsView: View {
    @AppStorage("videoQuality") private var quality = VideoQuality.high.rawValue  // "1080p"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Video quality", selection: $quality) {
                        ForEach(VideoQuality.allCases) { option in
                            Text(option.rawValue).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(VideoQuality(rawValue: quality)?.detail ?? "")
                        .font(.footnote)
                        .foregroundStyle(Angra.textSecondary)
                        // The description changes with the choice; a crossfade keeps
                        // the row from snapping between two different sentences.
                        .transition(.opacity)
                        .animation(Angra.spring, value: quality)
                } header: { Eyebrow("Capture") }
                .listRowBackground(rowBackground)

                Section {
                    LabeledContent("Captured") {
                        Text(RecordingStore.format(RecordingStore.usedBytes))
                            .monospacedDigit()
                            .foregroundStyle(Angra.textSecondary)
                    }
                    LabeledContent("Free space") {
                        Text(RecordingStore.format(RecordingStore.freeBytes))
                            .monospacedDigit()
                            .foregroundStyle(Angra.textSecondary)
                    }
                    Text("Recordings stay in this app's private storage. Nothing is uploaded or shared. Export them through the Files app under On My iPhone → EyeofAngra.")
                        .font(.footnote)
                        .foregroundStyle(Angra.textSecondary)
                } header: { Eyebrow("Storage") }
                .listRowBackground(rowBackground)

                Section {
                    NavigationLink {
                        SafetyLegalView()
                    } label: {
                        Label("Safety & Legal", systemImage: "hand.raised.fill")
                    }
                    LabeledContent("Version") {
                        Text(Bundle.main.version)
                            .monospacedDigit()
                            .foregroundStyle(Angra.textSecondary)
                    }
                    LabeledContent("Licence") {
                        Text("MIT").foregroundStyle(Angra.textSecondary)
                    }
                } header: { Eyebrow("About") }
                .listRowBackground(rowBackground)

                // Signature, not chrome: the wordmark closes the list the way a
                // maker's mark closes an object.
                Section {
                    VStack(spacing: 6) {
                        BrandWordmark(size: 22)
                        Text("Evidence, the moment it matters")
                            .font(.caption)
                            .tracking(0.6)
                            .foregroundStyle(Angra.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .listRowBackground(Color.clear)
                }
            }
            .tint(Angra.gold)
            .scrollContentBackground(.hidden)
            .background(Angra.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .principal) { BrandWordmark(size: 17) }
            }
        }
    }

    /// One material for every grouped row: lifted gradient plus a gold hairline.
    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: Angra.radiusCard, style: .continuous)
            .fill(Angra.cardGradient)
            .overlay(
                RoundedRectangle(cornerRadius: Angra.radiusCard, style: .continuous)
                    .strokeBorder(Angra.edgeLight, lineWidth: Angra.hairline)
            )
            .padding(.vertical, 2)
    }
}

extension Bundle {
    var version: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }
}
