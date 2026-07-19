import AVFoundation

final class VideoCaptureController: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var isRecording = false
    @Published var errorMessage: String?
    let session = AVCaptureSession()

    private let output = AVCaptureMovieFileOutput()
    private var isConfigured = false

    func startSession() {
        guard !isConfigured else {
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { videoOK in
            AVCaptureDevice.requestAccess(for: .audio) { audioOK in
                guard videoOK && audioOK else {
                    DispatchQueue.main.async {
                        self.errorMessage = "Camera and microphone access are required. Enable both in Settings."
                    }
                    return
                }
                self.configureSession()
            }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
    }

    func startRecording() {
        guard session.isRunning, !output.isRecording else { return }
        output.startRecording(to: RecordingStore.newFileURL(prefix: "VID", ext: "mp4"), recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        output.stopRecording()
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high
        if let camera = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: camera),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if let mic = AVCaptureDevice.default(for: .audio),
           let input = try? AVCaptureDeviceInput(device: mic),
           session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
        isConfigured = true
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    // MARK: - AVCaptureFileOutputRecordingDelegate

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            // Keep the file even on error: a partial recording is still evidence.
            if let error {
                self.errorMessage = "Recording ended with an error: \(error.localizedDescription)"
            }
        }
    }
}
