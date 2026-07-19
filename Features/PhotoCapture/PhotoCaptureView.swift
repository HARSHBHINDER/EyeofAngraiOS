import SwiftUI

struct PhotoCaptureView: View {
    @StateObject private var controller = PhotoCaptureController()
    @State private var photos = RecordingStore.list(prefix: "IMG")
    @State private var showConfirmation = false
    @State private var previewing: URL?

    private let columns = [GridItem(.adaptive(minimum: 70))]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black
                VStack(spacing: 12) {
                    Image(systemName: "camera")
                        .font(.title)
                        .foregroundStyle(.gray)
                    Text("Tap anywhere to take an evidence photo")
                        .foregroundStyle(.gray)
                }
                if showConfirmation {
                    Text("Photo captured")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .padding(10)
                        .background(.white, in: Capsule())
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { controller.capturePhoto() }
            .frame(maxHeight: .infinity)

            if let error = controller.errorMessage {
                Text(error).foregroundStyle(.red).padding(.horizontal)
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
                                .onTapGesture { previewing = url }
                        }
                    }
                }
                .padding(8)
            }
            .frame(height: 180)
        }
        .onAppear {
            photos = RecordingStore.list(prefix: "IMG")
            controller.startSession()
        }
        .onDisappear { controller.stopSession() }
        .onChange(of: controller.lastSavedAt) {
            photos = RecordingStore.list(prefix: "IMG")
            showConfirmation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { showConfirmation = false }
        }
        .fullScreenCover(item: $previewing) { url in
            ZStack {
                Color.black.ignoresSafeArea()
                if let image = UIImage(contentsOfFile: url.path) {
                    Image(uiImage: image).resizable().scaledToFit()
                }
            }
            .onTapGesture { previewing = nil }
        }
    }
}
