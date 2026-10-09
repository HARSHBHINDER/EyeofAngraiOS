import SwiftUI

struct AudioRecorderView: View {
    @ObservedObject private var controller = AudioRecorderController.shared
    @State private var recordings = RecordingStore.list(prefix: "AUD")
    @State private var elapsed = 0
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // The timer is the screen's thesis: large, serif, gold while live.
                Text(format(elapsed))
                    .font(Angra.timer(64))
                    .tracking(-1)
                    .foregroundStyle(controller.isRecording
                                     ? AnyShapeStyle(Angra.goldGradient)
                                     : AnyShapeStyle(Angra.textPrimary))
                    .contentTransition(.numericText())
                    .animation(Angra.spring, value: elapsed)

                status
                    .padding(.top, 18)

                if let error = controller.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Angra.record)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 14)
                }

                Spacer(minLength: 0)

                RecordButton(isActive: controller.isRecording) {
                    controller.isRecording ? controller.stop() : controller.start()
                }
                .padding(.bottom, 8)

                RecordingList(prefix: "AUD", recordings: $recordings)
                    .frame(height: 210)
            }
            .frame(maxWidth: .infinity)
            .background(background)
            .navigationTitle("Audio")
            .toolbar {
                ToolbarItem(placement: .principal) { BrandWordmark(size: 17) }
            }
        }
        .onAppear {
            recordings = RecordingStore.list(prefix: "AUD")
            pulse = true
        }
        .onReceive(tick) { _ in if controller.isRecording { elapsed += 1 } }
        .onChange(of: controller.isRecording) {
            elapsed = 0
            if !controller.isRecording { recordings = RecordingStore.list(prefix: "AUD") }
        }
    }

    /// A gold wash behind the timer, so the top of the screen has depth without
    /// another surface competing for attention.
    private var background: some View {
        ZStack {
            Angra.background
            RadialGradient(
                colors: [Angra.gold.opacity(controller.isRecording ? 0.16 : 0.07), .clear],
                center: UnitPoint(x: 0.5, y: 0.30),
                startRadius: 8, endRadius: 320
            )
            .animation(Angra.spring, value: controller.isRecording)
        }
        .ignoresSafeArea()
    }

    private var status: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(controller.isRecording ? Angra.record : Angra.textTertiary)
                .frame(width: 7, height: 7)
                // Slow breath, not a strobe — and stillness when the system asks.
                .opacity(controller.isRecording && pulse && !reduceMotion ? 0.35 : 1)
                .animation(controller.isRecording && !reduceMotion
                           ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                           : .default,
                           value: pulse)

            Text(controller.isRecording ? "Recording · continues if the screen locks" : "Ready")
                .font(.footnote)
                .foregroundStyle(controller.isRecording ? Angra.textPrimary : Angra.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Angra.gold.opacity(0.18), lineWidth: Angra.hairline))
    }

    private func format(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
