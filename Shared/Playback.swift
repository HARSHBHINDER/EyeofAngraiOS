import SwiftUI
import AVKit
import UIKit

/// Identity for sheet and cover presentation. A retroactive `URL: Identifiable`
/// conformance would break the day Apple adds their own.
struct MediaItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}

/// The one capture control. Three things carry its state at once — the centre
/// morphs circle to rounded square, the colour shifts, and the gold halo retracts —
/// so recording is never signalled by colour alone.
struct RecordButton: View {
    let isActive: Bool
    var isEnabled: Bool = true
    let action: () -> Void

    private var ring: Color { isEnabled ? Angra.textPrimary : Angra.textTertiary }
    private var centre: Color { isEnabled ? Angra.record : Angra.textTertiary }

    var body: some View {
        Button {
            // Fires with the visual change, on the same frame the shape morphs.
            UIImpactFeedbackGenerator(style: isActive ? .rigid : .heavy).impactOccurred()
            action()
        } label: {
            ZStack {
                // Idle halo: a soft gold presence that retracts the moment capture
                // begins, so the button reads as armed rather than decorative.
                Circle()
                    .fill(Angra.gold.opacity(isActive ? 0 : 0.16))
                    .frame(width: 104, height: 104)
                    .blur(radius: 12)

                Circle()
                    .strokeBorder(ring.opacity(0.9), lineWidth: 3)
                    .frame(width: 78, height: 78)

                RoundedRectangle(cornerRadius: isActive ? 7 : 30, style: .continuous)
                    .fill(centre)
                    .frame(width: isActive ? 30 : 60, height: isActive ? 30 : 60)
                    .shadow(color: centre.opacity(isActive ? 0.5 : 0), radius: 14)
            }
            .frame(width: 104, height: 104)
            .contentShape(Circle())
            // Momentum bounce: the shape change is the payoff of a deliberate press.
            .animation(Angra.springMomentum, value: isActive)
        }
        .buttonStyle(PressableButtonStyle(scale: 0.94))
        .disabled(!isEnabled)
        .accessibilityLabel(isActive ? "Stop recording" : "Start recording")
        .accessibilityHint(isActive ? "Ends the capture and saves it" : "Begins capturing evidence")
    }
}

/// Latest captures with tap-to-play and swipe-to-delete. AVKit's VideoPlayer
/// handles audio too, showing transport controls instead of a picture.
struct RecordingList: View {
    let prefix: String
    @Binding var recordings: [URL]
    @State private var playing: MediaItem?

    var body: some View {
        List {
            ForEach(recordings.prefix(10), id: \.self) { url in
                Button { playing = MediaItem(url: url) } label: {
                    RecordingRow(url: url)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            .onDelete { offsets in
                offsets.forEach { RecordingStore.delete(recordings[$0]) }
                recordings = RecordingStore.list(prefix: prefix)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .sheet(item: $playing) {
            VideoPlayer(player: AVPlayer(url: $0.url)).ignoresSafeArea()
        }
    }
}

/// One capture: kind mark, human time, size. The filename is machine detail and
/// stays out of the way.
private struct RecordingRow: View {
    let url: URL

    private var symbol: String {
        switch url.pathExtension {
        case "mp4": "video.fill"
        case "m4a": "waveform"
        default: "photo.fill"
        }
    }

    private var captured: String {
        let raw = url.deletingPathExtension().lastPathComponent
            .split(separator: "_").dropFirst().prefix(2).joined(separator: "_")
        let parser = DateFormatter()
        parser.dateFormat = "yyyyMMdd_HHmmss"
        parser.locale = Locale(identifier: "en_US_POSIX")
        guard let date = parser.date(from: raw) else { return url.lastPathComponent }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.footnote)
                .foregroundStyle(Angra.gold)
                .frame(width: 34, height: 34)
                .background(Angra.gold.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(captured)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Angra.textPrimary)
                Text(RecordingStore.format(RecordingStore.size(of: url)))
                    .font(.caption)
                    .foregroundStyle(Angra.textSecondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "play.circle.fill")
                .font(.title3)
                .foregroundStyle(Angra.textTertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .premiumCard(radius: Angra.radiusTile)
    }
}
