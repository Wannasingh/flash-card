import WidgetKit
import SwiftUI

struct StatsEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let dueCards: Int
}

struct StatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: Date(), streak: 5, dueCards: 12)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> ()) {
        let entry = StatsEntry(
            date: Date(),
            streak: WidgetDataStore.shared.getStreakCount(),
            dueCards: WidgetDataStore.shared.getDueCardsCount()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> ()) {
        let entry = StatsEntry(
            date: Date(),
            streak: WidgetDataStore.shared.getStreakCount(),
            dueCards: WidgetDataStore.shared.getDueCardsCount()
        )
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct StatsWidgetEntryView : View {
    var entry: StatsProvider.Entry

    var body: some View {
        ZStack {
            // Liquid Glass Background
            LinearGradient(colors: [Color(hex: "0D0221"), Color(hex: "240046")], startPoint: .topLeading, endPoint: .bottomTrailing)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(entry.streak) DAYS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.dueCards)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(Color(hex: "00F5FF"))
                    Text("CARDS DUE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            Color(hex: "0D0221")
        }
    }
}

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Your Progress")
        .description("Track your streak and due cards.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

