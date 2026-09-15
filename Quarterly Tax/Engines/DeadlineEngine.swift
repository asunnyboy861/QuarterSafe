import Foundation

struct DeadlineEngine {
    static let eastern = TimeZone(identifier: "America/New_York")!

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

    static func adjustedDueDate(baseline: Date, holidays: Set<Date>) -> Date {
        let cal = calendar
        var d = cal.startOfDay(for: baseline)
        while !isBusinessDay(d, cal: cal, holidays: holidays) {
            guard let next = cal.date(byAdding: .day, value: 1, to: d) else { break }
            d = cal.startOfDay(for: next)
        }
        return d
    }

    static func isBusinessDay(_ d: Date, cal: Calendar, holidays: Set<Date>) -> Bool {
        let wd = cal.component(.weekday, from: d)
        return wd != 1 && wd != 7 && !holidays.contains(cal.startOfDay(for: d))
    }

    static func deadlines(taxYear config: TaxYearConfig) -> [Quarter: Date] {
        var out: [Quarter: Date] = [:]
        let holidays = Set(config.federalHolidays.compactMap { parseISO($0) })
        for q in Quarter.allCases {
            guard let base = parseISO(config.federalDeadlines.baseline(for: q) ?? "") else { continue }
            out[q] = adjustedDueDate(baseline: base, holidays: holidays)
        }
        return out
    }

    static func nextDeadline(after date: Date = .now, deadlines: [Quarter: Date]) -> (quarter: Quarter, date: Date)? {
        let upcoming = deadlines
            .filter { $0.value >= Calendar.current.startOfDay(for: date) }
            .sorted { $0.value < $1.value }
        if let first = upcoming.first { return (first.key, first.value) }
        let all = deadlines.sorted { $0.value < $1.value }
        return all.first.map { ($0.key, $0.value) }
    }

    static func daysRemaining(until due: Date, from date: Date = .now) -> Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.startOfDay(for: due)
        return cal.dateComponents([.day], from: start, to: end).day ?? 0
    }

    static func reminderDates(due: Date) -> [Date] {
        [21, 14, 7, 1, 0].compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: due) }
    }
}
