import SwiftUI

struct VideoRecorderView: View {
    @ObservedObject private var controller = CaptureController.shared
    @ObservedObject private var audioWitness = AudioRecorderController.shared
    @State private var recordings = RecordingStore.list(prefix: "VID")

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .top) {
                if audioWitness.isRecording {
                    Color.black.overlay(
                        Text("Stop the audio witness before recording video — both need the microphone.")
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                    )
                } else {
                    CameraPreview(session: controller.session)
                }
                if controller.isRecording {
                    Label("Recording video + audio", systemImage: "record.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(.red, in: Capsule())
                        .padding(.top, 8)
                }
            }
            .frame(maxHeight: .infinity)

            if let error = controller.errorMessage {
                Text(error).foregroundStyle(.red).padding(.horizontal)
            }

            Button {
                controller.isRecording ? controller.stopRecording() : controller.startRecording()
            } label: {
                Text(controller.isRecording ? "Stop" : "Record")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(controller.isRecording ? Color.gray : Color.red, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding()
            .disabled(audioWitness.isRecording)

            RecordingList(prefix: "VID", recordings: $recordings)
                .frame(height: 220)
        }
        .onAppear {
            recordings = RecordingStore.list(prefix: "VID")
            if !audioWitness.isRecording { controller.start(mode: .video) }
        }
        // Left running while recording, so leaving the tab cannot cut the capture.
        .onDisappear { if !controller.isRecording { controller.stop() } }
        .onChange(of: controller.isRecording) {
            if !controller.isRecording { recordings = RecordingStore.list(prefix: "VID") }
        }
    }
}
