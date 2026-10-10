import AVFoundation
import UIKit

// Single AVCaptureSession shared by Video and Photo tabs — iOS allows only one.
final class CaptureController: NSObject, ObservableObject,
                               AVCaptureFileOutputRecordingDelegate,
                               AVCapturePhotoCaptureDelegate {

    static let shared = CaptureController()

    enum Mode { case video, photo }

    @Published var isRecording = false
    @Published var lastSavedAt: Date?
    @Published var errorMessage: String?

    /// Set by a widget deeplink: begin recording as soon as the session is live.
    var pendingAutoStart = false

    let session = AVCaptureSession()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private var mode: Mode?

    /// Requests only what the mode needs, then configures the session for it.
    func start(mode: Mode) {
        if self.mode == mode {
            // Pick up a quality change made in Settings since the session was built.
            if mode == .video, session.sessionPreset != videoPreset() {
                session.beginConfiguration()
                session.sessionPreset = videoPreset()
                session.commitConfiguration()
            }
            run { self.session.startRunning(); self.fireAutoStart() }
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

    /// The app is fixed in portrait, and so is every capture, however the phone is held.
    private func applyRotation(to connection: AVCaptureConnection?) {
        guard let connection, connection.isVideoRotationAngleSupported(90) else { return }
        connection.videoRotationAngle = 90
    }

    func startRecording() {
        applyRotation(to: movieOutput.connection(with: .video))
        guard session.isRunning, !movieOutput.isRecording else { return }
        // Record the way the iPhone Camera app does: HEVC in a QuickTime .mov,
        // falling back to H.264 on hardware without an HEVC encoder.
        if let connection = movieOutput.connection(with: .video),
           movieOutput.availableVideoCodecTypes.contains(.hevc) {
            movieOutput.setOutputSettings([AVVideoCodecKey: AVVideoCodecType.hevc], for: connection)
        }
        movieOutput.startRecording(to: RecordingStore.newFileURL(prefix: "VID", ext: "mov"),
                                   recordingDelegate: self)
        isRecording = true
    }

    func stopRecording() {
        movieOutput.stopRecording()
    }

    /// Extension matching the codec chosen for the photo in flight.
    private var photoExt = "jpg"

    func capturePhoto() {
        guard session.isRunning, mode == .photo else { return }
        // HEIC like the Camera app when the device supports it, JPEG otherwise.
        let heic = photoOutput.availablePhotoCodecTypes.contains(.hevc)
        photoExt = heic ? "heic" : "jpg"
        let settings = heic ? AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
                            : AVCapturePhotoSettings()
        applyRotation(to: photoOutput.connection(with: .video))
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Session setup

    private func configure(for mode: Mode) {
        session.beginConfiguration()
        // Video honours the quality chosen in Settings; photo always uses .photo.
        session.sessionPreset = mode == .photo ? .photo : videoPreset()

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
        run { self.session.startRunning(); self.fireAutoStart() }
    }

    /// After a widget deeplink, start recording once the session is live.
    private func fireAutoStart() {
        guard pendingAutoStart else { return }
        DispatchQueue.main.async {
            self.pendingAutoStart = false
            self.startRecording()
        }
    }

    /// Maps the Settings quality string to a preset, falling back to 1080p if the
    /// device can't do the chosen one (older phones have no 4K).
    private func videoPreset() -> AVCaptureSession.Preset {
        let preset: AVCaptureSession.Preset
        switch UserDefaults.standard.string(forKey: "videoQuality") {
        case "4K": preset = .hd4K3840x2160
        case "720p": preset = .hd1280x720
        default: preset = .hd1920x1080
        }
        return session.canSetSessionPreset(preset) ? preset : .hd1920x1080
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
                try data.write(to: RecordingStore.newFileURL(prefix: "IMG", ext: self.photoExt),
                               options: .atomic)
                self.lastSavedAt = Date()
            } catch {
                self.errorMessage = "Could not save photo: \(error.localizedDescription)"
            }
        }
    }
}
