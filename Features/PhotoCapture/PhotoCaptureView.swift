import SwiftUI

struct PhotoCaptureView: View {
    @ObservedObject private var controller = CaptureController.shared
    @State private var photos = RecordingStore.list(prefix: "IMG")
    @State private var showConfirmation = false
    @State private var previewing: MediaItem?

    private let columns = [GridItem(.adaptive(minimum: 70))]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Angra.background
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.title)
                        .foregroundStyle(Angra.gold)
                    Text("Tap anywhere to take an evidence photo")
                        .foregroundStyle(Angra.textSecondary)
                }
                if showConfirmation {
                    Label("Photo saved", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Angra.textPrimary)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Angra.success, in: Capsule())
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { controller.capturePhoto() }
            .frame(maxHeight: .infinity)

            if let error = controller.errorMessage {
                Text(error).font(.footnote).foregroundStyle(Angra.record)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    // ponytail: full-res images as thumbnails; downsample if the grid ever grows past ~20.
                    ForEach(photos.prefix(12), id: \.self) { url in
                        if let image = UIImage(contentsOfFile: url.path) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipped()
                                .onTapGesture { previewing = MediaItem(url: url) }
                        }
                    }
                }
                .padding(8)
            }
            .frame(height: 180)
        }
        .onAppear {
            photos = RecordingStore.list(prefix: "IMG")
            controller.start(mode: .photo)
        }
        .onDisappear { controller.stop() }
        .onChange(of: controller.lastSavedAt) {
            photos = RecordingStore.list(prefix: "IMG")
            showConfirmation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { showConfirmation = false }
        }
        .fullScreenCover(item: $previewing) { item in
            ZStack {
                Color.black.ignoresSafeArea()
                if let image = UIImage(contentsOfFile: item.url.path) {
                    Image(uiImage: image).resizable().scaledToFit()
                }
            }
            .onTapGesture { previewing = nil }
        }
    }
}

