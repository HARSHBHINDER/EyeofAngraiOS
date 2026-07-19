import AVFoundation

/// Owns the app's single AVCaptureSession.
///
/// iOS gives one session access to the camera at a time, so the Video and Photo
/// tabs share this one and swap its output when they appear. Two separate sessions
/// race for the camera and one of them silently fails to start.
final class CaptureController: NSObject, ObservableObject,
                               AVCaptureFileOutputRecordingDelegate,
                               AVCapturePhotoCaptureDelegate {

    static let shared = CaptureController()

    enum Mode { case video, photo }

    @Published var isRecording = false
    @Published var lastSavedAt: Date?
    @Published var errorMessage: String?

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var mode: Mode?

    /// Requests only what the mode needs, then configures the session for it.
    func start(mode: Mode) {
        if self.mode == mode {
            run { self.session.startRunning() }
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { cameraOK in
            guard cameraOK else {
                self.report("Camera access is required. Enable it in Settings.")
                return
            }
            guard mode == .video else {
                self.configure(for: mode)
                return
            }
            AVCaptureDevice.requestAccess(for: .audio) { micOK in
                guard micOK else {
                    self.report("Microphone access is required for video. Enable it in Settings.")
                    return
                }
                self.configure(for: mode)
            }
        }
    }

    func stop() {
        run { self.session.stopRunning() }
    }

    func startRecording() {
        guard session.isRunning, !movieOutput.isRecording else { return }
        movieOutput.startRecording(to: RecordingStore.newFileURL(prefix: "VID", ext: "mp4"),
                                   recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        movieOutput.stopRecording()
    }

    func capturePhoto() {
        guard session.isRunning, mode == .photo else { return }
        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    // MARK: - Session setup

    private func configure(for mode: Mode) {
        session.beginConfiguration()
        session.sessionPreset = mode == .video ? .high : .photo

        // Rebuilt each time: the mic belongs to video only, and the two outputs
        // cannot both hold the session.
        session.inputs.forEach(session.removeInput)
        session.outputs.forEach(session.removeOutput)

        addInput(.video)
        if mode == .video { addInput(.audio) }

        let output: AVCaptureOutput = mode == .video ? movieOutput : photoOutput
        if session.canAddOutput(output) { session.addOutput(output) }

        session.commitConfiguration()
        self.mode = mode
        run { self.session.startRunning() }
    }

    private func addInput(_ type: AVMediaType) {
        guard let device = AVCaptureDevice.default(for: type),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
    }

    private func run(_ work: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async(execute: work)
    }

    private func report(_ message: String) {
        DispatchQueue.main.async { self.errorMessage = message }
    }

    // MARK: - Delegates

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
            // The file is kept even on error: a partial recording is still evidence.
            if let error {
                self.errorMessage = "Recording ended with an error: \(error.localizedDescription)"
            }
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        DispatchQueue.main.async {
            if let error {
                self.errorMessage = "Photo failed: \(error.localizedDescription)"
                return
            }
            guard let data = photo.fileDataRepresentation() else {
                self.errorMessage = "Photo failed: no image data."
                return
            }
            do {
                try data.write(to: RecordingStore.newFileURL(prefix: "IMG", ext: "jpg"),
                               options: .atomic)
                self.lastSavedAt = Date()
            } catch {
                self.errorMessage = "Could not save photo: \(error.localizedDescription)"
            }
        }
    }
}
