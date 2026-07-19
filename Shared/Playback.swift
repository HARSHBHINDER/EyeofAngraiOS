import SwiftUI
import AVKit

/// Identity for sheet and cover presentation. A retroactive `URL: Identifiable`
/// conformance would break the day Apple adds their own.
struct MediaItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
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
