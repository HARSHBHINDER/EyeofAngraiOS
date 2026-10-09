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
    @Namespace private var chipNamespace

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                if files.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing captured yet", systemImage: "lock.shield")
                    } description: {
                        Text("Recordings you make appear here, held only on this device.")
                    }
                    .padding(.top, 72)
                } else {
                    LazyVGrid(columns: columns, spacing: 12) {
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Angra.background.ignoresSafeArea())
            .navigationTitle("Vault")
            .safeAreaInset(edge: .top) { filterBar }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(RecordingStore.format(RecordingStore.usedBytes))
                        .font(.caption.monospacedDigit())
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

    /// Floating chrome over the grid: translucent, with the selection sliding
    /// between chips rather than blinking from one to the next.
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases, id: \.self) { option in
                    let selected = filter == option
                    Text(option.rawValue)
                        .font(.subheadline.weight(selected ? .semibold : .regular))
                        .foregroundStyle(selected ? Angra.background : Angra.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background {
                            if selected {
                                Capsule()
                                    .fill(Angra.goldGradient)
                                    .matchedGeometryEffect(id: "chip", in: chipNamespace)
                            } else {
                                Capsule().fill(Angra.surfaceAlt)
                            }
                        }
                        .contentShape(Capsule())
                        .onTapGesture {
                            withAnimation(Angra.spring) { filter = option }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            // A soft edge where floating chrome meets content, not a hard rule.
            LinearGradient(colors: [Angra.gold.opacity(0.14), .clear],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 1)
        }
    }

    private func reload() {
        files = filter.prefixes
            .flatMap { RecordingStore.list(prefix: $0) }
            .sorted { $0.lastPathComponent.dropFirst(4) > $1.lastPathComponent.dropFirst(4) }
    }
}

/// Photos show themselves; audio and video get a mark, which avoids decoding a
/// frame for every tile. A scrim keeps the size legible over any image.
private struct Tile: View {
    let url: URL

    private var isPhoto: Bool { url.pathExtension == "jpg" }

    var body: some View {
        ZStack {
            if isPhoto, let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Angra.cardGradient
                Image(systemName: url.pathExtension == "mp4" ? "video.fill" : "waveform")
                    .font(.title3)
                    .foregroundStyle(Angra.goldGradient)
            }
        }
        .frame(height: 108)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Angra.radiusTile, style: .continuous))
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
                .frame(height: 46)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            Text(RecordingStore.format(RecordingStore.size(of: url)))
                .font(.caption2.weight(.medium).monospacedDigit())
                .foregroundStyle(Angra.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Angra.radiusTile, style: .continuous)
                .strokeBorder(Angra.gold.opacity(0.16), lineWidth: Angra.hairline)
        )
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
