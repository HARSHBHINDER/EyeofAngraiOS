import SwiftUI

struct AudioRecorderView: View {
    @ObservedObject private var controller = AudioRecorderController.shared
    @State private var recordings = RecordingStore.list(prefix: "AUD")

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            if controller.isRecording {
                Label("Recording audio (may continue in background)", systemImage: "record.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(10)
                    .background(.red, in: Capsule())
                    .padding(.horizontal)
            } else {
                Text("Audio recorder (can run in background)").font(.headline)
            }

            if let error = controller.errorMessage {
                Text(error).foregroundStyle(.red).padding(.horizontal)
            }

            Button {
                controller.isRecording ? controller.stop() : controller.start()
            } label: {
                Text(controller.isRecording ? "Stop" : "Start")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(controller.isRecording ? Color.gray : Color.red, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)

            Spacer()

            RecordingList(prefix: "AUD", recordings: $recordings)
                .frame(height: 260)
        }
        .onAppear { recordings = RecordingStore.list(prefix: "AUD") }
        .onChange(of: controller.isRecording) {
            if !controller.isRecording { recordings = RecordingStore.list(prefix: "AUD") }
        }
    }
}
