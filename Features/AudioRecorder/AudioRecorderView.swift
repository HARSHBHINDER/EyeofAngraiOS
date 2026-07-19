import SwiftUI

struct AudioRecorderView: View {
    @ObservedObject private var controller = AudioRecorderController.shared
    @State private var recordings = RecordingStore.list(prefix: "AUD")
    @State private var elapsed = 0

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                Text(format(elapsed))
                    .font(Angra.timer(56))
                    .foregroundStyle(Angra.textPrimary)

                Label(controller.isRecording ? "Recording — may continue in background"
                                             : "Ready",
                      systemImage: controller.isRecording ? "record.circle.fill" : "mic")
                    .font(.footnote)
                    .foregroundStyle(controller.isRecording ? Angra.textPrimary : Angra.textSecondary)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(controller.isRecording ? Angra.record : Angra.surfaceAlt,
                                in: Capsule())

                if let error = controller.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(Angra.record)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }

                Spacer()

                RecordButton(isActive: controller.isRecording) {
                    controller.isRecording ? controller.stop() : controller.start()
                }

                RecordingList(prefix: "AUD", recordings: $recordings)
                    .frame(height: 200)
            }
            .frame(maxWidth: .infinity)
            .background(Angra.background)
            .navigationTitle("Audio")
        }
        .onAppear { recordings = RecordingStore.list(prefix: "AUD") }
        .onReceive(tick) { _ in if controller.isRecording { elapsed += 1 } }
        .onChange(of: controller.isRecording) {
            elapsed = 0
            if !controller.isRecording { recordings = RecordingStore.list(prefix: "AUD") }
        }
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
