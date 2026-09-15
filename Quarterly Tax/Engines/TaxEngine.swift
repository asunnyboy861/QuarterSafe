import Foundation

struct TaxInput {
    var netProfit: Decimal
    var priorYearTotalTax: Decimal?
    var priorYearAGI: Decimal?
    var filingStatus: FilingStatus
    var w2Withholding: Decimal
}

struct TaxResult {
    var seTax: Decimal
    var fedTax: Decimal
    var stateTax: Decimal
    var safeHarborTarget: Decimal
    var requiredTotal: Decimal
    var perQuarter: Decimal
    var needsQuarterlies: Bool
    var mode: Mode

    enum Mode: String {
        case full
        case simple
    }

    static func zero(mode: Mode) -> TaxResult {
        TaxResult(seTax: 0, fedTax: 0, stateTax: 0, safeHarborTarget: 0,
                  requiredTotal: 0, perQuarter: 0, needsQuarterlies: false, mode: mode)
    }
}

struct TaxEngine {
    static func compute(input: TaxInput, config: TaxYearConfig, state: AppStateTax?) -> TaxResult {
        let seBase = input.netProfit * Decimal(config.seTax.netEarningsFactor)
        let ssTax = min(seBase, Decimal(config.seTax.ssWageBase)) * Decimal(0.124)
        let medi = seBase * Decimal(0.029)
        let seTax = max(0, ssTax + medi)

        let agi = max(0, input.netProfit - seTax / 2)
        let std = config.standardDeduction(for: input.filingStatus)
        let taxable = max(0, agi - std)
        let fedTax = progressiveTax(taxable, brackets: config.brackets(for: input.filingStatus).map {
            TaxYearConfig.Bracket(upTo: $0.upTo, rate: $0.rate)
        })

        let stateTax = stateTaxFor(agi: agi, state: state)

        let totalTax = seTax + fedTax + stateTax

        guard totalTax >= Decimal(config.safeHarbor.smallBalanceException) else {
            return .zero(mode: input.priorYearTotalTax == nil ? .simple : .full)
        }

        var target = totalTax * Decimal(config.safeHarbor.currentYearPct)
        var mode = TaxResult.Mode.full
        if let prior = input.priorYearTotalTax, prior > 0 {
            let isHighAGI = (input.priorYearAGI ?? 0) > Decimal(config.safeHarbor.highAGIThreshold)
            let ratio = isHighAGI ? config.safeHarbor.priorYearPctHighAGI : config.safeHarbor.priorYearPct
            target = min(target, prior * Decimal(ratio))
        } else {
            mode = .simple
        }

        let required = max(0, target - input.w2Withholding)
        return TaxResult(seTax: seTax, fedTax: fedTax, stateTax: stateTax,
                         safeHarborTarget: target, requiredTotal: required,
                         perQuarter: required / 4,
                         needsQuarterlies: true, mode: mode)
    }

    static func stateTaxFor(agi: Decimal, state: AppStateTax?) -> Decimal {
        guard let state, state.hasIncomeTax else { return 0 }
        if let flat = state.flatRate {
            return max(0, agi) * Decimal(flat)
        }
        if let brackets = state.brackets {
            return progressiveTax(agi, brackets: brackets.map {
                TaxYearConfig.Bracket(upTo: $0.upTo, rate: $0.rate)
            })
        }
        return 0
    }

    static func progressiveTax(_ income: Decimal, brackets: [TaxYearConfig.Bracket]) -> Decimal {
        var tax: Decimal = 0
        var floor: Decimal = 0
        for b in brackets {
            guard income > floor else { break }
            let cap = b.upTo.map { Decimal($0) } ?? Decimal.greatestFiniteMagnitude
            if cap > floor {
                tax += (min(income, cap) - floor) * Decimal(b.rate)
            }
            floor = cap
        }
        return tax
    }
}
