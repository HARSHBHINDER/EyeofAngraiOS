import AVFoundation

final class PhotoCaptureController: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var lastSavedAt: Date?
    @Published var errorMessage: String?
    let session = AVCaptureSession()

    private let output = AVCapturePhotoOutput()
    private var isConfigured = false

    func startSession() {
        guard !isConfigured else {
            DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else {
                DispatchQueue.main.async {
                    self.errorMessage = "Camera access is required. Enable it in Settings."
                }
                return
            }
            self.configureSession()
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { self.session.stopRunning() }
    }

    func capturePhoto() {
        guard session.isRunning else { return }
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        if let camera = AVCaptureDevice.default(for: .video),
           let input = try? AVCaptureDeviceInput(device: camera),
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

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
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
                try data.write(to: RecordingStore.newFileURL(prefix: "IMG", ext: "jpg"), options: .atomic)
                self.lastSavedAt = Date()
            } catch {
                self.errorMessage = "Could not save photo: \(error.localizedDescription)"
            }
        }
    }
}
