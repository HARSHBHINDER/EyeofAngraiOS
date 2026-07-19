import SwiftUI

struct VideoRecorderView: View {
    @ObservedObject private var controller = CaptureController.shared
    @ObservedObject private var audioWitness = AudioRecorderController.shared
    @State private var recordings = RecordingStore.list(prefix: "VID")
    @State private var elapsed = 0

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if audioWitness.isRecording {
                    Angra.background.overlay(
                        Text("Audio recording is running.\nStop it before recording video — both need the microphone.")
                            .foregroundStyle(Angra.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    )
                } else {
                    CameraPreview(session: controller.session)
                }

                if controller.isRecording {
                    Label(format(elapsed), systemImage: "record.circle.fill")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Angra.textPrimary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Angra.record, in: Capsule())
                        .padding(.top, 12)
                }
            }
            .frame(maxHeight: .infinity)

            if let error = controller.errorMessage {
                Text(error).font(.footnote).foregroundStyle(Angra.record)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }

            RecordButton(isActive: controller.isRecording,
                         isEnabled: !audioWitness.isRecording) {
                controller.isRecording ? controller.stopRecording() : controller.startRecording()
            }
            .padding(.vertical, 14)

            RecordingList(prefix: "VID", recordings: $recordings)
                .frame(height: 190)
        }
        .background(Angra.background)
        .onAppear {
            recordings = RecordingStore.list(prefix: "VID")
            if !audioWitness.isRecording { controller.start(mode: .video) }
        }
        // Left running while recording, so leaving the tab cannot cut the capture.
        .onDisappear { if !controller.isRecording { controller.stop() } }
        .onReceive(tick) { _ in if controller.isRecording { elapsed += 1 } }
        .onChange(of: controller.isRecording) {
            elapsed = 0
            if !controller.isRecording { recordings = RecordingStore.list(prefix: "VID") }
        }
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
