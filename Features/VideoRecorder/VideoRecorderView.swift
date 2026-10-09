import SwiftUI
import UIKit

struct VideoRecorderView: View {
    @ObservedObject private var controller = CaptureController.shared
    @ObservedObject private var audioWitness = AudioRecorderController.shared
    @State private var recordings = RecordingStore.list(prefix: "VID")
    @State private var priorBrightness = UIScreen.main.brightness

    var body: some View {
        Group {
            if controller.isRecording {
                // Stealth: screen is black and the backlight is off while it films.
                // Tap anywhere to stop.
                Color.black.ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { controller.stopRecording() }
            } else {
                idle
            }
        }
        .onAppear {
            recordings = RecordingStore.list(prefix: "VID")
            if !audioWitness.isRecording { controller.start(mode: .video) }
        }
        // Left running while recording, so leaving the tab cannot cut the capture.
        .onDisappear { if !controller.isRecording { controller.stop() } }
        .onChange(of: controller.isRecording) {
            if controller.isRecording {
                priorBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 0
            } else {
                UIScreen.main.brightness = priorBrightness
                recordings = RecordingStore.list(prefix: "VID")
            }
        }
    }

    private var idle: some View {
        VStack(spacing: 0) {
            viewfinder
                .padding(.horizontal, 16)
                .padding(.top, 8)

            if let error = controller.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(Angra.record)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 10)
            }

            RecordButton(isActive: false, isEnabled: !audioWitness.isRecording) {
                controller.startRecording()
            }
            .padding(.vertical, 6)

            Text("Recording blacks out the screen. Tap anywhere to stop.")
                .font(.caption)
                .foregroundStyle(Angra.textTertiary)
                .padding(.bottom, 6)

            RecordingList(prefix: "VID", recordings: $recordings)
                .frame(height: 190)
        }
        .background(Angra.background.ignoresSafeArea())
    }

    /// The viewfinder is treated as an instrument: inset, cornered, hairlined —
    /// not a raw camera feed bleeding to the edges.
    private var viewfinder: some View {
        ZStack {
            if audioWitness.isRecording {
                Angra.cardGradient
                Text("Audio recording is running.\nStop it before recording video — both need the microphone.")
                    .font(.subheadline)
                    .foregroundStyle(Angra.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(24)
            } else {
                CameraPreview(session: controller.session)
                FramingCorners()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Angra.gold.opacity(0.22), lineWidth: Angra.hairline)
        )
    }
}

/// Four corner brackets — the framing marks of a viewfinder, drawn rather than
/// pulled from an icon set so they stay hairline-thin at any size.
private struct FramingCorners: View {
    var body: some View {
        GeometryReader { geo in
            let arm: CGFloat = 22
            let inset: CGFloat = 16
            Path { p in
                let maxX = geo.size.width - inset
                let maxY = geo.size.height - inset
                // Top-left
                p.move(to: CGPoint(x: inset, y: inset + arm))
                p.addLine(to: CGPoint(x: inset, y: inset))
                p.addLine(to: CGPoint(x: inset + arm, y: inset))
                // Top-right
                p.move(to: CGPoint(x: maxX - arm, y: inset))
                p.addLine(to: CGPoint(x: maxX, y: inset))
                p.addLine(to: CGPoint(x: maxX, y: inset + arm))
                // Bottom-right
                p.move(to: CGPoint(x: maxX, y: maxY - arm))
                p.addLine(to: CGPoint(x: maxX, y: maxY))
                p.addLine(to: CGPoint(x: maxX - arm, y: maxY))
                // Bottom-left
                p.move(to: CGPoint(x: inset + arm, y: maxY))
                p.addLine(to: CGPoint(x: inset, y: maxY))
                p.addLine(to: CGPoint(x: inset, y: maxY - arm))
            }
            .stroke(Angra.textPrimary.opacity(0.55), lineWidth: 1.5)
        }
        .allowsHitTesting(false)
    }
}
