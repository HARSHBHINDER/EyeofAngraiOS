import SwiftUI
import AVKit

extension URL: Identifiable {
    public var id: String { absoluteString }
}

/// Plays both video and audio files. For audio, VideoPlayer just shows transport controls.
struct PlayerSheet: View {
    let url: URL

    var body: some View {
        VideoPlayer(player: AVPlayer(url: url))
            .ignoresSafeArea()
    }
}

/// Latest recordings with tap-to-play and swipe-to-delete. Used by the Video and Audio tabs.
struct RecordingList: View {
    let prefix: String
    @Binding var recordings: [URL]
    @State private var playing: URL?

    var body: some View {
        List {
            ForEach(recordings.prefix(10), id: \.self) { url in
                Button(url.lastPathComponent) { playing = url }
            }
            .onDelete { offsets in
                offsets.forEach { RecordingStore.delete(recordings[$0]) }
                recordings = RecordingStore.list(prefix: prefix)
            }
        }
        .sheet(item: $playing) { PlayerSheet(url: $0) }
    }
}
