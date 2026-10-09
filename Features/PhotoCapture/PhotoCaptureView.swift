import SwiftUI
import UIKit

/// Stealth capture: the screen is truly black and the backlight is dimmed to
/// zero, so the phone looks off while it takes evidence photos. A tap anywhere
/// captures; a success haptic confirms without lighting the screen. Review the
/// photos in the Vault tab.
struct PhotoCaptureView: View {
    @ObservedObject private var controller = CaptureController.shared
    @State private var priorBrightness = UIScreen.main.brightness

    var body: some View {
        Color.black
            .ignoresSafeArea()
            .contentShape(Rectangle())
            .onTapGesture { controller.capturePhoto() }
            .overlay(alignment: .bottom) {
                if let error = controller.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(Angra.record)
                        .multilineTextAlignment(.center).padding()
                }
            }
            .onAppear {
                priorBrightness = UIScreen.main.brightness
                UIScreen.main.brightness = 0
                controller.start(mode: .photo)
            }
            // ponytail: brightness restores on tab switch; iOS restores it on the
            // next unlock even if the app is killed mid-stealth.
            .onDisappear {
                UIScreen.main.brightness = priorBrightness
                controller.stop()
            }
            .onChange(of: controller.lastSavedAt) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
    }
}
