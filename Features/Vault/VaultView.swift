import SwiftUI
import AVKit
import Photos

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
    @State private var notice: String?
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
                                    if url.isPhoto || url.isVideo {
                                        Button("Save to Photos", systemImage: "square.and.arrow.down") {
                                            Task { notice = await PhotosSaver.save(url) }
                                        }
                                    }
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
            .overlay(alignment: .bottom) {
                if let notice {
                    Text(notice)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Angra.background)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(Angra.goldGradient, in: Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .task {
                            try? await Task.sleep(for: .seconds(2.5))
                            withAnimation(Angra.spring) { self.notice = nil }
                        }
                }
            }
            .animation(Angra.spring, value: notice)
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
            if item.url.isPhoto {
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

/// Photos and videos show a real frame; audio gets a gold mark. Length and capture
/// time ride on a scrim so the tile says what it is at a glance.
private struct Tile: View {
    let url: URL
    @State private var thumb: UIImage?
    @State private var duration: Double?

    var body: some View {
        ZStack {
            if let thumb {
                Image(uiImage: thumb).resizable().scaledToFill()
            } else {
                Angra.cardGradient
                Image(systemName: url.isVideo ? "video.fill" : url.isPhoto ? "photo.fill" : "waveform")
                    .font(.title3)
                    .foregroundStyle(Angra.goldGradient)
            }
        }
        .frame(height: 108)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: Angra.radiusTile, style: .continuous))
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .center, endPoint: .bottom)
                .frame(height: 52)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            if let duration {
                Text((url.isVideo ? "▶ " : "♪ ") + Self.clock(duration))
                    .font(.caption2.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Angra.textPrimary)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(6)
            }
        }
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 1) {
                Text(Self.capturedAt(url))
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Angra.textPrimary)
                Text(RecordingStore.format(RecordingStore.size(of: url)))
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(Angra.textSecondary)
            }
            .padding(.horizontal, 8).padding(.vertical, 6)
        }
        .overlay(
            RoundedRectangle(cornerRadius: Angra.radiusTile, style: .continuous)
                .strokeBorder(Angra.gold.opacity(0.16), lineWidth: Angra.hairline)
        )
        .task(id: url) { await load() }
    }

    private func load() async {
        if url.isPhoto {
            thumb = UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: CGSize(width: 240, height: 240))
            return
        }
        let asset = AVURLAsset(url: url)
        if let seconds = try? await asset.load(.duration).seconds, seconds.isFinite { duration = seconds }
        guard url.isVideo else { return }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true   // portrait clips stay upright
        generator.maximumSize = CGSize(width: 360, height: 360)
        // One second in skips the black first frame some captures start with.
        if let frame = try? await generator.image(at: CMTime(seconds: 1, preferredTimescale: 600)).image {
            thumb = UIImage(cgImage: frame)
        }
    }

    static func clock(_ seconds: Double) -> String {
        let t = Int(seconds)
        return t >= 3600 ? String(format: "%d:%02d:%02d", t / 3600, t % 3600 / 60, t % 60)
                         : String(format: "%d:%02d", t / 60, t % 60)
    }

    /// "25 Aug, 14:09" from the VID_yyyyMMdd_HHmmss name.
    static func capturedAt(_ url: URL) -> String {
        let raw = url.deletingPathExtension().lastPathComponent
            .split(separator: "_").dropFirst().prefix(2).joined(separator: "_")
        let parser = DateFormatter()
        parser.dateFormat = "yyyyMMdd_HHmmss"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: raw) else { return "" }
        return date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }
}

/// Copies a capture into the user's Photos library. Recordings are already HEVC
/// .mov / HEIC — the Camera app's own formats — so Photos plays them as-is.
private enum PhotosSaver {
    static func save(_ url: URL) async -> String {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return "Allow EyeofAngra to add to Photos in Settings"
        }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: url.isVideo ? .video : .photo, fileURL: url, options: nil)
            }
            return "Saved to Photos"
        } catch {
            return "Could not save to Photos"
        }
    }
}

private extension URL {
    var isPhoto: Bool { ["jpg", "jpeg", "heic"].contains(pathExtension.lowercased()) }
    var isVideo: Bool { ["mov", "mp4"].contains(pathExtension.lowercased()) }
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
