import Testing
import Foundation
@testable import Quarterly_Tax

struct DeadlineEngineTests {
    let config = TaxYearConfig.load()!

    @Test func q2_2026StaysOnJune15BusinessDay() {
        let deadlines = DeadlineEngine.deadlines(taxYear: config)
        let cal = DeadlineEngine.calendar
        let q2 = deadlines[.q2]!
        #expect(cal.component(.month, from: q2) == 6)
        #expect(cal.component(.day, from: q2) == 15)
        #expect(cal.component(.weekday, from: q2) != 1)
        #expect(cal.component(.weekday, from: q2) != 7)
    }

    @Test func q1_2026IsApril15() {
        let deadlines = DeadlineEngine.deadlines(taxYear: config)
        let cal = DeadlineEngine.calendar
        let q1 = deadlines[.q1]!
        #expect(cal.component(.month, from: q1) == 4)
        #expect(cal.component(.day, from: q1) == 15)
    }

    @Test func q4_2027CrossesYear() {
        let deadlines = DeadlineEngine.deadlines(taxYear: config)
        let cal = DeadlineEngine.calendar
        let q4 = deadlines[.q4]!
        #expect(cal.component(.year, from: q4) == 2027)
        #expect(cal.component(.month, from: q4) == 1)
        #expect(cal.component(.day, from: q4) == 15)
    }

    @Test func weekendShiftsToMonday() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = DeadlineEngine.eastern
        let saturday = DeadlineEngine.parseISO("2026-01-31")!
        #expect(cal.component(.weekday, from: saturday) == 7)
        let adjusted = DeadlineEngine.adjustedDueDate(baseline: saturday, holidays: [])
        #expect(cal.component(.weekday, from: adjusted) == 2)
        #expect(cal.component(.day, from: adjusted) == 2)
    }

    @Test func holidayShiftsToNextBusinessDay() {
        let holiday = DeadlineEngine.parseISO("2026-01-01")!
        let adjusted = DeadlineEngine.adjustedDueDate(baseline: holiday, holidays: [holiday])
        let cal = DeadlineEngine.calendar
        #expect(cal.component(.day, from: adjusted) == 2)
    }
}

struct TaxEngineTests {
    let config = TaxYearConfig.load()!

    private func makeInput(net: Decimal, prior: Decimal? = nil, agi: Decimal? = nil) -> TaxInput {
        TaxInput(netProfit: net, priorYearTotalTax: prior, priorYearAGI: agi,
                 filingStatus: .single, w2Withholding: 0)
    }

    @Test func smallBalanceExemption() {
        let result = TaxEngine.compute(input: makeInput(net: 3000), config: config, state: nil)
        #expect(!result.needsQuarterlies)
        #expect(result.requiredTotal == 0)
    }

    @Test func simpleModeWithoutPriorYear() {
        let result = TaxEngine.compute(input: makeInput(net: 100000), config: config, state: nil)
        #expect(result.mode == .simple)
        #expect(result.seTax > 0)
        #expect(result.fedTax > 0)
        #expect(result.needsQuarterlies)
    }

    @Test func safeHarborTakesLowerOfCurrentAndPrior() {
        let current = TaxEngine.compute(input: makeInput(net: 100000), config: config, state: nil)
        let priorHeavy = TaxEngine.compute(input: makeInput(net: 100000, prior: 5000, agi: 80000), config: config, state: nil)
        #expect(priorHeavy.mode == .full)
        #expect(priorHeavy.safeHarborTarget <= current.safeHarborTarget)
        #expect(priorHeavy.safeHarborTarget == min(current.safeHarborTarget, 5000))
    }

    @Test func highAGIUses110Percent() {
        let result = TaxEngine.compute(input: makeInput(net: 400000, prior: 20000, agi: 200000), config: config, state: nil)
        #expect(result.mode == .full)
        let current = TaxEngine.compute(input: makeInput(net: 400000), config: config, state: nil)
        #expect(result.safeHarborTarget == min(current.safeHarborTarget, 22000))
    }

    @Test func zeroStateTaxForNoTaxStates() {
        let texas = AppStateTax(code: "TX", name: "Texas", flatRate: 0.0, brackets: nil)
        let result = TaxEngine.compute(input: makeInput(net: 80000), config: config, state: texas)
        #expect(result.stateTax == 0)
    }

    @Test func flatStateTax() {
        let illinois = AppStateTax(code: "IL", name: "Illinois", flatRate: 0.0495, brackets: nil)
        let result = TaxEngine.compute(input: makeInput(net: 100000), config: config, state: illinois)
        #expect(result.stateTax > 0)
    }

    @Test func progressiveBracketMath() {
        let brackets = [
            TaxYearConfig.Bracket(upTo: 1000, rate: 0.10),
            TaxYearConfig.Bracket(upTo: 3000, rate: 0.20),
            TaxYearConfig.Bracket(upTo: nil, rate: 0.30)]
        let tax = TaxEngine.progressiveTax(Decimal(4000), brackets: brackets)
        let expected = Decimal(1000) * Decimal(0.10) + Decimal(2000) * Decimal(0.20) + Decimal(1000) * Decimal(0.30)
        #expect(tax == expected)
    }

    @Test func seTaxBaseUses9235Factor() {
        let result = TaxEngine.compute(input: makeInput(net: 100000), config: config, state: nil)
        let base = Decimal(100000) * Decimal(0.9235)
        let expectedSE = base * Decimal(0.124) + base * Decimal(0.029)
        #expect(result.seTax == expectedSE)
    }
}

struct JarEngineTests {
    @Test func progressCapsAtOne() {
        #expect(JarEngine.jarProgress(setAside: 5000, requiredTotal: 2400) == 1.0)
    }

    @Test func progressZeroWhenNothingSetAside() {
        #expect(JarEngine.jarProgress(setAside: 0, requiredTotal: 2400) == 0.0)
    }

    @Test func simpleThirtyPercent() {
        #expect(JarEngine.setAsideSimple(amount: 1000) == Decimal(300))
    }

    @Test func carryforwardNeverNegative() {
        #expect(JarEngine.carryforward(paidForQuarter: 100, quarterDue: 600) == 0)
        #expect(JarEngine.carryforward(paidForQuarter: 800, quarterDue: 600) == 200)
    }

    @Test func quarterDueSplitsAcrossRemainingQuarters() {
        #expect(JarEngine.quarterDue(safeHarborTarget: 4800, paidThisYear: 1200, quartersElapsed: 1) == Decimal(1200))
    }

    @Test func moneyParsingHandlesCommasAndDollar() {
        #expect(Money.parse("$2,437.50") == Decimal(string: "2437.50"))
        #expect(Money.parse("") == nil)
    }
}
