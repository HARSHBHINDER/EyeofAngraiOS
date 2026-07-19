import SwiftUI
import AVKit

struct VaultView: View {
    private enum Filter: String, CaseIterable {
        case all = "All", video = "Video", audio = "Audio", photo = "Photo"
        var prefixes: [String] {
            switch self {
            case .all: ["VID", "AUD", "IMG"]
            case .video: ["VID"]
            case .audio: ["AUD"]
            case .photo: ["IMG"]
            }
        }
    }

    @State private var filter: Filter = .all
    @State private var files: [URL] = []
    @State private var playing: MediaItem?
    @State private var pendingDelete: MediaItem?

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(files, id: \.self) { url in
                        Tile(url: url)
                            .onTapGesture { playing = MediaItem(url: url) }
                            .contextMenu {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    pendingDelete = MediaItem(url: url)
                                }
                            }
                    }
                }
                .padding(12)

                if files.isEmpty {
                    ContentUnavailableView("Nothing captured yet",
                                           systemImage: "lock",
                                           description: Text("Recordings you make appear here, stored only on this device."))
                        .padding(.top, 60)
                }
            }
            .background(Angra.background)
            .navigationTitle("Vault")
            .safeAreaInset(edge: .top) { filterBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(RecordingStore.format(RecordingStore.usedBytes))
                        .font(.footnote)
                        .foregroundStyle(Angra.textSecondary)
                }
            }
        }
        .onAppear(perform: reload)
        .onChange(of: filter) { reload() }
        .sheet(item: $playing) { item in
            if item.url.pathExtension == "jpg" {
                ImageViewer(url: item.url)
            } else {
                VideoPlayer(player: AVPlayer(url: item.url)).ignoresSafeArea()
            }
        }
        .confirmationDialog("Delete this recording?",
                            isPresented: .constant(pendingDelete != nil),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let item = pendingDelete { RecordingStore.delete(item.url) }
                pendingDelete = nil
                reload()
            }
            Button("Cancel", role: .cancel) { pendingDelete = nil }
        } message: {
            Text("This permanently removes it from the device. Evidence cannot be recovered.")
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { option in
                    Text(option.rawValue)
                        .font(.subheadline.weight(filter == option ? .semibold : .regular))
                        .padding(.horizontal, 14).padding(.vertical, 7)
                        .background(filter == option ? Angra.gold : Angra.surfaceAlt,
                                    in: Capsule())
                        .foregroundStyle(filter == option ? Angra.background : Angra.textSecondary)
                        .onTapGesture { filter = option }
                }
            }
            .padding(.horizontal, 12).padding(.bottom, 8)
        }
        .background(Angra.background)
    }

    private func reload() {
        files = filter.prefixes
            .flatMap { RecordingStore.list(prefix: $0) }
            .sorted { $0.lastPathComponent.dropFirst(4) > $1.lastPathComponent.dropFirst(4) }
    }
}

/// Photos show themselves; audio and video get a symbol, which avoids decoding a
/// frame for every tile.
private struct Tile: View {
    let url: URL

    var body: some View {
        ZStack {
            if url.pathExtension == "jpg", let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Angra.surface
                Image(systemName: url.pathExtension == "mp4" ? "video.fill" : "waveform")
                    .font(.title2)
                    .foregroundStyle(Angra.gold)
            }
        }
        .frame(height: 104)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottomLeading) {
            Text(RecordingStore.format(RecordingStore.size(of: url)))
                .font(.caption2)
                .foregroundStyle(Angra.textPrimary)
                .padding(4)
                .background(.black.opacity(0.55), in: Capsule())
                .padding(6)
        }
    }
}

private struct ImageViewer: View {
    let url: URL
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFit()
            }
        }
    }
}
