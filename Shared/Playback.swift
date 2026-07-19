import SwiftUI
import AVKit

/// Identity for sheet and cover presentation. A retroactive `URL: Identifiable`
/// conformance would break the day Apple adds their own.
struct MediaItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// The one capture control, shared by the Video and Audio tabs.
/// The centre morphs circle → rounded square when active, so recording state is
/// carried by shape as well as colour.
struct RecordButton: View {
    let isActive: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(isEnabled ? Angra.textPrimary : Angra.textSecondary, lineWidth: 3)
                    .frame(width: 78, height: 78)
                RoundedRectangle(cornerRadius: isActive ? 6 : 30)
                    .fill(isEnabled ? Angra.record : Angra.textSecondary)
                    .frame(width: isActive ? 30 : 60, height: isActive ? 30 : 60)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
        }
        .disabled(!isEnabled)
        .accessibilityLabel(isActive ? "Stop recording" : "Start recording")
    }
}

/// Latest recordings with tap-to-play and swipe-to-delete. Used by the Video and
/// Audio tabs — AVKit's VideoPlayer handles audio files too, showing transport
/// controls instead of a picture.
struct RecordingList: View {
    let prefix: String
    @Binding var recordings: [URL]
    @State private var playing: MediaItem?

    var body: some View {
        List {
            ForEach(recordings.prefix(10), id: \.self) { url in
                Button(url.lastPathComponent) { playing = MediaItem(url: url) }
            }
            .onDelete { offsets in
                offsets.forEach { RecordingStore.delete(recordings[$0]) }
                recordings = RecordingStore.list(prefix: prefix)
            }
        }
        .sheet(item: $playing) {
            VideoPlayer(player: AVPlayer(url: $0.url)).ignoresSafeArea()
        }
    }
}
