import AVFoundation

final class AudioRecorderController: ObservableObject {
    /// Shared so the Video tab can refuse to steal the microphone from an active witness recording.
    static let shared = AudioRecorderController()

    @Published var isRecording = false
    @Published var errorMessage: String?
    private var recorder: AVAudioRecorder?

    private init() {
        // A call or Siri kills the recorder. Stop cleanly so the UI never claims a dead recording.
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification,
                                               object: nil, queue: .main) { [weak self] _ in
            guard let self, self.isRecording else { return }
            self.stop()
            self.errorMessage = "Recording stopped by a system interruption. File saved."
        }
    }

    func start() {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                guard granted else {
                    self.errorMessage = "Microphone access is required. Enable it in Settings."
                    return
                }
                self.beginRecording()
            }
        }
    }

    func stop() {
        recorder?.stop()
        recorder = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
    }

    private func beginRecording() {
        // The permission prompt is async, so two quick taps can both land here.
        // A second recorder would orphan the first one's file mid-write.
        guard recorder == nil else { return }
        do {
            // .playAndRecord + the "audio" background mode keeps this running when the app is backgrounded.
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            ]
            let recorder = try AVAudioRecorder(url: RecordingStore.newFileURL(prefix: "AUD", ext: "m4a"),
                                               settings: settings)
            recorder.record()
            self.recorder = recorder
            isRecording = true
        } catch {
            errorMessage = "Could not start recording: \(error.localizedDescription)"
        }
    }
}
