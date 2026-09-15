import Foundation

enum Quarter: String, CaseIterable, Codable, Identifiable {
    case q1, q2, q3, q4

    var id: String { key }
    var key: String {
        switch self {
        case .q1: "Q1"
        case .q2: "Q2"
        case .q3: "Q3"
        case .q4: "Q4"
        }
    }
}

enum FilingStatus: String, CaseIterable, Codable, Identifiable {
    case single
    case marriedJoint
    case hoh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .single: "Single"
        case .marriedJoint: "Married filing jointly"
        case .hoh: "Head of household"
        }
    }
}

enum PaymentMethod: String, CaseIterable, Identifiable {
    case irsDirectPay = "IRS Direct Pay"
    case eftps = "EFTPS"
    case check = "Check"
    case other = "Other"

    var id: String { rawValue }
}

enum IncomeRhythm: String, CaseIterable, Codable, Identifiable {
    case fullTimeSelfEmployed
    case sideHustle
    case seasonal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullTimeSelfEmployed: "Full-time self-employed"
        case .sideHustle: "Side hustle"
        case .seasonal: "Seasonal"
        }
    }

    var defaultReserveRate: Double {
        switch self {
        case .fullTimeSelfEmployed: 0.30
        case .sideHustle: 0.25
        case .seasonal: 0.30
        }
    }
}

enum Money {
    static func parse(_ text: String) -> Decimal? {
        let cleaned = text.replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "$", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        return Decimal(string: cleaned)
    }

    static func text(_ value: Decimal, style: FormattingStyle = .whole) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
        if style == .whole {
            formatter.maximumFractionDigits = 0
        }
        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? "$0"
    }

    enum FormattingStyle {
        case whole
        case exact
    }
}

struct AppStateTax: Codable, Identifiable, Hashable {
    var code: String
    var name: String
    var flatRate: Double?
    var brackets: [StateBracket]?

    var id: String { code }

    var hasIncomeTax: Bool {
        flatRate != nil || !(brackets ?? []).isEmpty
    }
}

struct StateBracket: Codable, Hashable {
    var upTo: Double?
    var rate: Double
}
