import WidgetKit
import SwiftUI

// A widget cannot capture on its own — it can only open the app via a deeplink.
// The app foregrounds, jumps to the tab, and auto-arms the recording.
private let gold = Color(red: 0.831, green: 0.686, blue: 0.216)

private struct Entry: TimelineEntry { let date: Date }

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> Entry { Entry(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        completion(Entry(date: .now))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        completion(Timeline(entries: [Entry(date: .now)], policy: .never))
    }
}

// MARK: - Home screen: Video + Audio

private struct HomeView: View {
    var body: some View {
        HStack(spacing: 10) {
            link("eyeofangra://video", "video.fill", "Video", Color(red: 0.776, green: 0.157, blue: 0.157))
            link("eyeofangra://audio", "waveform", "Audio", gold)
        }
        .containerBackground(.black, for: .widget)
    }

    private func link(_ url: String, _ symbol: String, _ title: String, _ tint: Color) -> some View {
        Link(destination: URL(string: url)!) {
            VStack(spacing: 6) {
                Image(systemName: symbol).font(.title)
                Text(title).font(.caption.weight(.semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

private struct HomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EyeofAngraHome", provider: Provider()) { _ in HomeView() }
            .configurationDisplayName("Quick Record")
            .description("Start a video or audio recording instantly.")
            .supportedFamilies([.systemMedium])
    }
}

// MARK: - Lock screen: Video only

private struct LockView: View {
    var body: some View {
        Image(systemName: "video.fill")
            .font(.title2)
            .widgetURL(URL(string: "eyeofangra://video")!)
            .containerBackground(.clear, for: .widget)
    }
}

private struct LockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EyeofAngraLock", provider: Provider()) { _ in LockView() }
            .configurationDisplayName("Record")
            .description("Start a video recording.")
            .supportedFamilies([.accessoryCircular])
    }
}

@main
struct EyeofAngraWidgetBundle: WidgetBundle {
    var body: some Widget {
        HomeWidget()
        LockWidget()
    }
}
