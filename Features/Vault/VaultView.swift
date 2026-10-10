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
    // Selection mode: tap toggles, the bottom bar acts on every ticked item.
    @State private var selecting = false
    @State private var selected: Set<URL> = []
    @State private var confirmBatchDelete = false
    @Namespace private var chipNamespace

    // Tiles per row, set by pinching and remembered; 3 matches the Photos default.
    @AppStorage("vaultColumns") private var columns = 3
    // Drag-select: frames of visible tiles, and the run being swept.
    @State private var tileFrames: [URL: CGRect] = [:]
    @State private var dragAnchor: Int?
    @State private var dragBase: Set<URL> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                if !files.isEmpty {
                    Text(selecting ? "Tap, or swipe sideways across tiles to select" : "Pinch to resize")
                        .font(.caption2)
                        .foregroundStyle(Angra.textTertiary)
                        .padding(.top, 4)
                }
                if files.isEmpty {
                    ContentUnavailableView {
                        Label("Nothing captured yet", systemImage: "lock.shield")
                    } description: {
                        Text("Recordings you make appear here, held only on this device.")
                    }
                    .padding(.top, 72)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: columns), spacing: 2) {
                        ForEach(files, id: \.self) { url in
                            Tile(url: url, columns: columns)
                                .background {
                                    GeometryReader { g in
                                        Color.clear.preference(key: TileFrames.self, value: [url: g.frame(in: .named("grid"))])
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if selecting { SelectionTick(on: selected.contains(url)) }
                                }
                                .overlay {
                                    if selecting && selected.contains(url) {
                                        Rectangle().fill(.white.opacity(0.18))
                                    }
                                }
                                .onTapGesture {
                                    if selecting {
                                        if selected.contains(url) { selected.remove(url) } else { selected.insert(url) }
                                    } else {
                                        playing = MediaItem(url: url)
                                    }
                                }
                                .contextMenu {
                                    if url.isPhoto || url.isVideo {
                                        Button("Save to Photos", systemImage: "square.and.arrow.down") {
                                            Task { notice = await PhotosSaver.save([url], move: false) }
                                        }
                                    }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        pendingDelete = MediaItem(url: url)
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 24)
                    .coordinateSpace(name: "grid")
                    .onPreferenceChange(TileFrames.self) { tileFrames = $0 }
                    // Sideways swipe in select mode sweeps a run of tiles, as in Photos;
                    // vertical movement is left to the scroll view.
                    .simultaneousGesture(selecting ? sweepGesture : nil)
                }
            }
            .scrollDisabled(dragAnchor != nil)
            // Pinch steps the grid, like Photos: spread for bigger tiles, pinch for more.
            .simultaneousGesture(
                MagnifyGesture().onEnded { value in
                    withAnimation(Angra.spring) {
                        if value.magnification > 1.2, columns > 1 { columns -= 1 }
                        else if value.magnification < 0.8, columns < 7 { columns += 1 }
                    }
                }
            )
            .background(Angra.background.ignoresSafeArea())
            .navigationTitle(selecting ? "\(selected.count) selected" : "Vault")
            .safeAreaInset(edge: .top) { filterBar }
            .safeAreaInset(edge: .bottom) { if selecting { actionBar } }
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
                ToolbarItem(placement: .topBarLeading) {
                    if !files.isEmpty {
                        Button(selecting ? "Cancel" : "Select") {
                            withAnimation(Angra.spring) { selecting.toggle(); selected = [] }
                        }
                        .tint(Angra.gold)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if selecting {
                        Button(selected.count == files.count ? "None" : "All") {
                            selected = selected.count == files.count ? [] : Set(files)
                        }
                        .tint(Angra.gold)
                    } else {
                        Text(RecordingStore.format(RecordingStore.usedBytes))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(Angra.textSecondary)
                    }
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
        .confirmationDialog("Delete \(selected.count) \(selected.count == 1 ? "item" : "items")?",
                            isPresented: $confirmBatchDelete,
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                selected.forEach(RecordingStore.delete)
                endSelection()
            }
        } message: {
            Text("They will be permanently removed from this device. Evidence cannot be recovered.")
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

    private var sweepGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .named("grid"))
            .onChanged { value in
                if dragAnchor == nil {
                    guard abs(value.translation.width) > abs(value.translation.height),
                          let start = index(at: value.startLocation) else { return }
                    dragAnchor = start
                    dragBase = selected
                }
                guard let anchor = dragAnchor, let i = index(at: value.location) else { return }
                selected = dragBase.union(files[min(anchor, i)...max(anchor, i)])
            }
            .onEnded { _ in dragAnchor = nil }
    }

    // ponytail: linear scan of visible tile frames; fine for a vault, index by row
    // and column if it ever holds thousands of items.
    private func index(at point: CGPoint) -> Int? {
        files.firstIndex { tileFrames[$0]?.contains(point) == true }
    }

    private func endSelection() {
        withAnimation(Angra.spring) { selecting = false; selected = [] }
        reload()
    }

    /// Batch actions. Photos takes video and photos; Export opens the share sheet
    /// (Save to Files, AirDrop, any app) and carries every type, audio included.
    private var actionBar: some View {
        let chosen = files.filter(selected.contains)
        let enabled = !chosen.isEmpty
        return HStack {
            Button {
                Task { notice = await PhotosSaver.save(chosen, move: false); endSelection() }
            } label: { Label("Save", systemImage: "square.and.arrow.down") }
            Spacer()
            Button {
                Task { notice = await PhotosSaver.save(chosen, move: true); endSelection() }
            } label: { Label("Move", systemImage: "photo.on.rectangle") }
            Spacer()
            ShareLink(items: chosen) { Label("Export", systemImage: "square.and.arrow.up") }
            Spacer()
            Button(role: .destructive) { confirmBatchDelete = true } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(Angra.record)
        }
        .labelStyle(.titleAndIcon)
        .font(.footnote.weight(.medium))
        .tint(Angra.gold)
        .disabled(!enabled)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Angra.gold.opacity(0.18)).frame(height: Angra.hairline)
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
private struct TileFrames: PreferenceKey {
    static var defaultValue: [URL: CGRect] = [:]
    static func reduce(value: inout [URL: CGRect], nextValue: () -> [URL: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct Tile: View {
    let url: URL
    let columns: Int
    private var roomy: Bool { columns <= 3 }
    @State private var thumb: UIImage?
    @State private var duration: Double?

    var body: some View {
        // A Photos-style square: edge to edge, no card chrome.
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let thumb {
                    Image(uiImage: thumb).resizable().scaledToFill()
                } else {
                    ZStack {
                        Angra.surface
                        Image(systemName: url.isVideo ? "video.fill" : url.isPhoto ? "photo.fill" : "waveform")
                            .font(roomy ? .title3 : .footnote)
                            .foregroundStyle(Angra.goldGradient)
                    }
                }
            }
            .clipped()
            .overlay(alignment: .bottom) {
                if duration != nil || roomy {
                    LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                        .frame(height: roomy ? 34 : 20)
                        .allowsHitTesting(false)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let duration {
                    Text(Self.clock(duration))
                        .font(.system(size: roomy ? 11 : 9, weight: .semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(5)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if roomy {
                    Text(Self.capturedAt(url))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Angra.textPrimary)
                        .padding(5)
                }
            }
            .task(id: "\(url)-\(columns <= 2)") { await load() }
    }

    private func load() async {
        if url.isPhoto {
            // Sharper decode when tiles are big; cheap when they are small.
            let side: CGFloat = columns <= 2 ? 720 : 360
            thumb = UIImage(contentsOfFile: url.path)?.preparingThumbnail(of: CGSize(width: side, height: side))
            return
        }
        let asset = AVURLAsset(url: url)
        if let seconds = try? await asset.load(.duration).seconds, seconds.isFinite { duration = seconds }
        guard url.isVideo else { return }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true   // portrait clips stay upright
        generator.maximumSize = columns <= 2 ? CGSize(width: 720, height: 720) : CGSize(width: 360, height: 360)
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

/// Gold filled tick when chosen, an empty ring otherwise.
private struct SelectionTick: View {
    let on: Bool
    var body: some View {
        ZStack {
            Circle().fill(on ? AnyShapeStyle(Angra.goldGradient) : AnyShapeStyle(.black.opacity(0.4)))
            Circle().strokeBorder(Angra.textPrimary, lineWidth: 1.5)
            if on {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Angra.background)
            }
        }
        .frame(width: 22, height: 22)
        .padding(6)
    }
}

/// Puts captures into the user's Photos library. Recordings are already HEVC .mov
/// and HEIC, the Camera app's own formats, so Photos plays them as-is.
private enum PhotosSaver {
    /// Move hands the file itself to Photos instead of copying it, so a multi-GB
    /// video moves without duplicating it or loading the phone.
    static func save(_ urls: [URL], move: Bool) async -> String {
        let media = urls.filter { $0.isPhoto || $0.isVideo }
        let audio = urls.count - media.count
        guard !media.isEmpty else { return "Photos cannot hold audio. Use Export instead." }
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            return "Allow EyeofAngra to add to Photos in Settings"
        }
        var saved = 0
        for url in media {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let options = PHAssetResourceCreationOptions()
                    options.shouldMoveFile = move
                    PHAssetCreationRequest.forAsset()
                        .addResource(with: url.isVideo ? .video : .photo, fileURL: url, options: options)
                }
                saved += 1
            } catch {
                continue
            }
        }
        var message = "\(move ? "Moved" : "Saved") \(saved) to Photos"
        if saved < media.count { message += " · \(media.count - saved) failed" }
        if audio > 0 { message += " · audio skipped, use Export" }
        return message
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
