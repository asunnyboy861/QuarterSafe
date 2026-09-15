import Foundation

struct TaxYearConfig: Codable {
    var taxYear: Int
    var version: String
    var reviewedDate: String
    var seTax: SETaxConfig
    var standardDeduction: StandardDeductionConfig
    var bracketsSingle: [Bracket]
    var bracketsMarriedJoint: [Bracket]
    var bracketsHoh: [Bracket]
    var safeHarbor: SafeHarborConfig
    var federalDeadlines: FederalDeadlines
    var otherDeadlines: OtherDeadlines
    var federalHolidays: [String]
    var stateTable: String

    struct SETaxConfig: Codable {
        var rate: Double
        var netEarningsFactor: Double
        var ssWageBase: Double
    }

    struct StandardDeductionConfig: Codable {
        var single: Double
        var marriedJoint: Double
        var hoh: Double
    }

    struct Bracket: Codable {
        var upTo: Double?
        var rate: Double
    }

    struct SafeHarborConfig: Codable {
        var currentYearPct: Double
        var priorYearPct: Double
        var priorYearPctHighAGI: Double
        var highAGIThreshold: Double
        var smallBalanceException: Double
    }

    struct FederalDeadlines: Codable {
        var q1: String
        var q2: String
        var q3: String
        var q4: String

        func baseline(for quarter: Quarter) -> String? {
            switch quarter {
            case .q1: q1
            case .q2: q2
            case .q3: q3
            case .q4: q4
            }
        }
    }

    struct OtherDeadlines: Codable {
        var forms1099: String
        var annualFiling: String
        var extensionFiling: String
    }

    static func load(taxYear: Int = 2026) -> TaxYearConfig? {
        guard let url = Bundle.main.url(forResource: "TaxYearConfig-\(taxYear)", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TaxYearConfig.self, from: data)
    }

    static func loadStates(taxYear: Int = 2026) -> [AppStateTax] {
        guard let url = Bundle.main.url(forResource: "states-\(taxYear)", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let states = try? JSONDecoder().decode([AppStateTax].self, from: data) else { return [] }
        return states
    }

    func brackets(for status: FilingStatus) -> [Bracket] {
        switch status {
        case .single: bracketsSingle
        case .marriedJoint: bracketsMarriedJoint
        case .hoh: bracketsHoh
        }
    }

    func standardDeduction(for status: FilingStatus) -> Decimal {
        switch status {
        case .single: Decimal(standardDeduction.single)
        case .marriedJoint: Decimal(standardDeduction.marriedJoint)
        case .hoh: Decimal(standardDeduction.hoh)
        }
    }

    func state(named code: String, states: [AppStateTax]) -> AppStateTax? {
        states.first { $0.code == code }
    }
}
