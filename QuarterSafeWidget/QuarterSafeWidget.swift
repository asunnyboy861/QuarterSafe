import WidgetKit
import SwiftUI

@main
struct QuarterSafeWidgetBundle: WidgetBundle {
    var body: some Widget {
        QuarterSafeDeadlineWidget()
    }
}

enum WidgetQuarter: String, CaseIterable {
    case q1, q2, q3, q4
    var key: String {
        switch self {
        case .q1: "Q1"
        case .q2: "Q2"
        case .q3: "Q3"
        case .q4: "Q4"
        }
    }
}

struct WidgetConfig: Codable {
    var taxYear: Int
    var federalDeadlines: FederalDeadlines
    var federalHolidays: [String]

    struct FederalDeadlines: Codable {
        var q1: String
        var q2: String
        var q3: String
        var q4: String

        func baseline(for q: WidgetQuarter) -> String? {
            switch q {
            case .q1: q1
            case .q2: q2
            case .q3: q3
            case .q4: q4
            }
        }
    }

    static func load() -> WidgetConfig? {
        guard let url = Bundle.main.url(forResource: "TaxYearConfig-2026", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetConfig.self, from: data)
    }
}

struct WidgetDeadline {
    var quarter: WidgetQuarter
    var date: Date
}

enum WidgetDeadlineEngine {
    static var eastern: TimeZone { TimeZone(identifier: "America/New_York") ?? .current }

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = eastern
        return cal
    }

    static func parseISO(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = eastern
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    static func deadlines(config: WidgetConfig) -> [Date] {
        let holidays = Set(config.federalHolidays.compactMap { parseISO($0) })
        return WidgetQuarter.allCases.compactMap { q in
            guard let base = parseISO(config.federalDeadlines.baseline(for: q) ?? "") else { return nil }
            return adjusted(base: base, holidays: holidays)
        }.sorted()
    }

    static func adjusted(base: Date, holidays: Set<Date>) -> Date {
        let cal = calendar
        var d = cal.startOfDay(for: base)
        while !business(d, cal: cal, holidays: holidays) {
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = cal.startOfDay(for: next)
        }
        return d
    }

    static func business(_ d: Date, cal: Calendar, holidays: Set<Date>) -> Bool {
        let wd = cal.component(.weekday, from: d)
        return wd != 1 && wd != 7 && !holidays.contains(cal.startOfDay(for: d))
    }

    static func nextDeadline(from date: Date = .now) -> WidgetDeadline? {
        guard let config = WidgetConfig.load() else { return nil }
        let all = deadlines(config: config)
        let upcoming = all.first { $0 >= Calendar.current.startOfDay(for: date) } ?? all.first
        guard let due = upcoming else { return nil }
        let keyed = WidgetQuarter.allCases.first { q in
            guard let base = parseISO(config.federalDeadlines.baseline(for: q) ?? "") else { return false }
            return adjusted(base: base, holidays: Set(config.federalHolidays.compactMap { parseISO($0) })) == due
        } ?? .q3
        return WidgetDeadline(quarter: keyed, date: due)
    }
}

struct DeadlineEntry: TimelineEntry {
    var date: Date
    var deadline: WidgetDeadline?
    var jarProgress: Double
    var jarAmountText: String
}

struct DeadlineProvider: TimelineProvider {
    func placeholder(in context: Context) -> DeadlineEntry {
        DeadlineEntry(date: .now, deadline: WidgetDeadlineEngine.nextDeadline(), jarProgress: 0.6, jarAmountText: "$2,437")
    }

    func getSnapshot(in context: Context, completion: @escaping (DeadlineEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DeadlineEntry>) -> Void) {
        let entry = currentEntry()
        let next = Calendar.current.date(byAdding: .hour, value: 6, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }

    private func currentEntry() -> DeadlineEntry {
        let defaults = UserDefaults(suiteName: "group.com.zzoutuo.QuarterSafe")
        let progress = defaults?.double(forKey: "jarProgress") ?? 0
        let amount = defaults?.string(forKey: "jarAmountText") ?? ""
        return DeadlineEntry(date: .now, deadline: WidgetDeadlineEngine.nextDeadline(), jarProgress: progress, jarAmountText: amount)
    }
}

struct QuarterSafeDeadlineWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QuarterSafeDeadlineWidget", provider: DeadlineProvider()) { entry in
            QuarterSafeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Tax Deadline Countdown")
        .description("Next quarterly deadline and your tax jar progress.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct QuarterSafeWidgetEntryView: View {
    var entry: DeadlineEntry

    @Environment(\.widgetFamily) private var family
    @Environment(\.widgetRenderingMode) private var renderingMode

    private var daysRemaining: Int {
        guard let deadline = entry.deadline else { return 0 }
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: entry.date), to: cal.startOfDay(for: deadline.date)).day ?? 0
    }

    var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            systemView
        }
    }

    private var circularView: some View {
        ZStack {
            if let deadline = entry.deadline {
                VStack {
                    Text(deadline.quarter.key)
                        .font(.system(size: 8, weight: .semibold))
                        .opacity(0.7)
                    Text("\(max(0, daysRemaining))")
                        .font(.title3.bold())
                        .monospacedDigit()
                    Text("days")
                        .font(.system(size: 8))
                }
            } else {
                Image(systemName: "calendar.badge.clock")
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let deadline = entry.deadline {
                HStack(spacing: 4) {
                    Text(deadline.quarter.key)
                        .font(.caption.bold())
                    Text("estimated tax")
                        .font(.caption2)
                        .opacity(0.6)
                }
                Text("Due \(deadline.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .opacity(0.8)
                Text("in \(max(0, daysRemaining)) days")
                    .font(.headline)
                    .monospacedDigit()
                if !entry.jarAmountText.isEmpty {
                    Text("Jar \(Int((entry.jarProgress * 100).rounded()))%")
                        .font(.caption2)
                        .monospacedDigit()
                }
            } else {
                Text("QuarterSafe").font(.caption.bold())
                Text("Add income to start tracking").font(.caption2).opacity(0.7)
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }

    private var inlineView: some View {
        Text(entry.deadline.map { "\($0.quarter.key) tax due in \(max(0, daysRemaining))d" } ?? "QuarterSafe")
            .containerBackground(for: .widget) { Color.clear }
    }

    private var systemView: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let deadline = entry.deadline {
                HStack {
                    Text(deadline.quarter.key)
                        .font(.caption.bold())
                        .foregroundStyle(.green)
                    Spacer()
                    Text(deadline.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(max(0, daysRemaining))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("days until deadline")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if !entry.jarAmountText.isEmpty {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.25))
                            Capsule().fill(Color.green)
                                .frame(width: max(6, geo.size.width * entry.jarProgress))
                        }
                    }
                    .frame(height: 8)
                    Text("Jar \(Int((entry.jarProgress * 100).rounded()))% of \(entry.jarAmountText)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text("Open the app to set your jar")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("QuarterSafe")
                    .font(.headline)
                Text("No deadlines configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(4)
        .containerBackground(for: .widget) { Color(.systemBackground).opacity(0.001) }
    }
}
