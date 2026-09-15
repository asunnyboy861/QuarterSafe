import Foundation

struct JarEngine {
    static func jarProgress(setAside: Decimal, requiredTotal: Decimal) -> Double {
        guard requiredTotal > 0 else { return 1 }
        let ratio = setAside / requiredTotal
        return min(1, max(0, Double(truncating: NSDecimalNumber(decimal: ratio))))
    }

    static func setAsideSimple(amount: Decimal, rate: Double = 0.30) -> Decimal {
        max(0, amount * Decimal(rate))
    }

    static func setAsideFull(amount: Decimal, target: Decimal, projectedAnnualIncome: Decimal) -> Decimal {
        guard projectedAnnualIncome > 0 else { return setAsideSimple(amount: amount) }
        let share = target / projectedAnnualIncome
        return max(0, amount * share)
    }

    static func quarterDue(safeHarborTarget: Decimal, paidThisYear: Decimal, quartersElapsed: Int) -> Decimal {
        guard quartersElapsed < 4, quartersElapsed >= 0 else { return max(0, safeHarborTarget - paidThisYear) }
        let remaining = 4 - quartersElapsed
        let outstanding = max(0, safeHarborTarget - paidThisYear)
        return outstanding / Decimal(remaining)
    }

    static func carryforward(paidForQuarter: Decimal, quarterDue: Decimal) -> Decimal {
        max(0, paidForQuarter - quarterDue)
    }

    static func projectedAnnualIncome(yearToDate: Decimal, currentDate: Date) -> Decimal {
        let cal = Calendar.current
        let dayOfYear = cal.ordinality(of: .day, in: .year, for: currentDate) ?? 1
        let daysInYear = cal.range(of: .day, in: .year, for: currentDate)?.count ?? 365
        guard dayOfYear > 0 else { return yearToDate * 4 }
        let ratio = Decimal(dayOfYear) / Decimal(daysInYear)
        guard ratio > 0 else { return yearToDate * 4 }
        return yearToDate / ratio
    }
}
