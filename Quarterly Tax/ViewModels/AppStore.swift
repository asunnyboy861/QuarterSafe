import Foundation
import SwiftUI
import SwiftData
import Observation

@Observable
@MainActor
final class AppStore {
    static let shared = AppStore()

    var modelContext: ModelContext?
    var config: TaxYearConfig
    var states: [AppStateTax]

    private(set) var profile: Profile?
    private(set) var incomes: [IncomeEvent] = []
    private(set) var expenses: [ExpenseEvent] = []
    private(set) var payments: [Payment] = []

    private(set) var result: TaxResult = .zero(mode: .simple)
    private(set) var deadlines: [Quarter: Date] = [:]
    private(set) var paidThisYear: Decimal = 0
    private(set) var nextDue: (quarter: Quarter, date: Date)?
    private(set) var jarProgress: Double = 0
    private(set) var paymentsByQuarter: [Quarter: Decimal] = [:]

    var lastSaveHint: Decimal?
    var showConfetti = false
    var pendingDeepLinkQuarter: Quarter?
    var lastIncomeJumpWarning: Double?

    var currentTaxYear: Int { config.taxYear }

    init() {
        config = TaxYearConfig.load() ?? TaxYearConfig(
            taxYear: 2026, version: "2026.1", reviewedDate: "2026-10-02",
            seTax: .init(rate: 0.153, netEarningsFactor: 0.9235, ssWageBase: 184500),
            standardDeduction: .init(single: 16100, marriedJoint: 32200, hoh: 24150),
            bracketsSingle: [], bracketsMarriedJoint: [], bracketsHoh: [],
            safeHarbor: .init(currentYearPct: 0.9, priorYearPct: 1.0, priorYearPctHighAGI: 1.1,
                              highAGIThreshold: 150000, smallBalanceException: 1000),
            federalDeadlines: .init(q1: "2026-04-15", q2: "2026-06-15", q3: "2026-09-15", q4: "2027-01-15"),
            otherDeadlines: .init(forms1099: "2026-02-02", annualFiling: "2026-04-15", extensionFiling: "2026-10-15"),
            federalHolidays: [], stateTable: "states-2026.json")
        states = TaxYearConfig.loadStates()
    }

    func attach(context: ModelContext) {
        self.modelContext = context
        loadAll()
    }

    func loadAll() {
        guard let context = modelContext else { return }
        let profileDescriptor = FetchDescriptor<Profile>()
        let existingProfiles = (try? context.fetch(profileDescriptor)) ?? []
        if let existing = existingProfiles.first {
            profile = existing
        } else {
            let newProfile = Profile()
            context.insert(newProfile)
            profile = newProfile
        }
        let incomeDescriptor = FetchDescriptor<IncomeEvent>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        incomes = ((try? context.fetch(incomeDescriptor)) ?? []).filter { !$0.isDeleted }
        let expenseDescriptor = FetchDescriptor<ExpenseEvent>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        expenses = ((try? context.fetch(expenseDescriptor)) ?? []).filter { !$0.isDeleted }
        let paymentDescriptor = FetchDescriptor<Payment>(sortBy: [SortDescriptor(\.paidAt, order: .reverse)])
        payments = (try? context.fetch(paymentDescriptor)) ?? []
        recompute()
    }

    var stateRule: AppStateTax? {
        guard let profile else { return nil }
        return states.first { $0.code == profile.stateCode }
    }

    var yearToDateIncome: Decimal {
        let cal = Calendar.current
        let year = cal.component(.year, from: .now)
        return incomes.filter { cal.component(.year, from: $0.date) == year }.reduce(0) { $0 + $1.amount }
    }

    var yearToDateExpenses: Decimal {
        let cal = Calendar.current
        let year = cal.component(.year, from: .now)
        return expenses.filter { cal.component(.year, from: $0.date) == year }.reduce(0) { $0 + $1.amount }
    }

    var netProfit: Decimal { max(0, yearToDateIncome - yearToDateExpenses) }

    var quartersElapsed: Int {
        guard let next = nextDue else { return 0 }
        return switch next.quarter {
        case .q1: 0
        case .q2: 1
        case .q3: 2
        case .q4: 3
        }
    }

    var isSimpleMode: Bool {
        result.mode == .simple
    }

    func recompute() {
        deadlines = DeadlineEngine.deadlines(taxYear: config)
        nextDue = DeadlineEngine.nextDeadline(deadlines: deadlines)
        let cal = Calendar.current
        let year = cal.component(.year, from: .now)
        paidThisYear = payments.filter { $0.taxYear == year }.reduce(0) { $0 + $1.amount }
        paymentsByQuarter = Dictionary(grouping: payments.filter { $0.taxYear == year }) { $0.quarter }
            .mapValues { $0.reduce(0) { $0 + $1.amount } }

        let priorTax = profile?.priorYearTotalTax
        let priorAGI = profile?.priorYearAGI
        let useFullEngine = priorTax != nil && PurchaseManager.shared.isPro

        let input = TaxInput(
            netProfit: netProfit,
            priorYearTotalTax: useFullEngine ? priorTax : nil,
            priorYearAGI: useFullEngine ? priorAGI : nil,
            filingStatus: profile?.filingStatus ?? .single,
            w2Withholding: 0)
        result = TaxEngine.compute(input: input, config: config, state: stateRule)

        let reserved = profile?.reservedJarBalance ?? 0
        jarProgress = JarEngine.jarProgress(setAside: paidThisYear + reserved, requiredTotal: result.requiredTotal)
        checkIncomeJump()
        persistWidgetSnapshot()
    }

    private func checkIncomeJump() {
        guard yearToDateIncome > 0 else {
            lastIncomeJumpWarning = nil
            return
        }
        let cal = Calendar.current
        let year = cal.component(.year, from: .now)
        let lastYear = incomes.filter { cal.component(.year, from: $0.date) == year - 1 }.reduce(0) { $0 + $1.amount }
        guard lastYear > 0 else {
            lastIncomeJumpWarning = nil
            return
        }
        let growth = Double(truncating: NSDecimalNumber(decimal: (yearToDateIncome - lastYear) / lastYear))
        lastIncomeJumpWarning = growth >= 0.4 ? growth : nil
    }

    func setAsideFor(amount: Decimal) -> Decimal {
        switch result.mode {
        case .simple:
            return JarEngine.setAsideSimple(amount: amount, rate: profile?.incomeRhythm.defaultReserveRate ?? 0.30)
        case .full:
            let projected = JarEngine.projectedAnnualIncome(yearToDate: yearToDateIncome, currentDate: .now)
            return JarEngine.setAsideFull(amount: amount, target: result.safeHarborTarget, projectedAnnualIncome: projected)
        }
    }

    func addIncome(amount: Decimal, clientName: String) {
        guard let context = modelContext, amount > 0 else { return }
        let event = IncomeEvent(amount: amount, clientName: clientName)
        context.insert(event)
        try? context.save()
        loadAll()
        lastSaveHint = setAsideFor(amount: amount)
    }

    func addExpense(amount: Decimal, note: String) {
        guard let context = modelContext, amount > 0 else { return }
        let event = ExpenseEvent(amount: amount, note: note)
        context.insert(event)
        try? context.save()
        loadAll()
    }

    func markPaid(quarter: Quarter, amount: Decimal, method: PaymentMethod,
                  confirmationNumber: String, proofPhotoData: Data?, note: String) {
        guard let context = modelContext else { return }
        let payment = Payment(quarter: quarter, taxYear: config.taxYear, amount: amount,
                              method: method.rawValue, confirmationNumber: confirmationNumber,
                              proofPhotoData: proofPhotoData, note: note)
        context.insert(payment)
        try? context.save()
        ReminderScheduler.cancel(quarter: quarter)
        loadAll()
        showConfetti = true
        persistWidgetSnapshot()
    }

    func updateProfile(stateCode: String? = nil, filingStatus: FilingStatus? = nil,
                       priorYearTax: Decimal?? = nil, priorYearAGI: Decimal?? = nil,
                       incomeRhythm: IncomeRhythm? = nil, reservedBalance: Decimal?? = nil,
                       onboardingComplete: Bool? = nil) {
        guard let profile else { return }
        if let stateCode { profile.stateCode = stateCode }
        if let filingStatus { profile.filingStatusRaw = filingStatus.rawValue }
        if let priorYearTax { profile.priorYearTotalTaxText = priorYearTax.map { NSDecimalNumber(decimal: $0).stringValue } ?? "" }
        if let priorYearAGI { profile.priorYearAGIText = priorYearAGI.map { NSDecimalNumber(decimal: $0).stringValue } ?? "" }
        if let incomeRhythm { profile.incomeRhythmRaw = incomeRhythm.rawValue }
        if let reservedBalance { profile.reservedJarBalanceText = NSDecimalNumber(decimal: reservedBalance ?? 0).stringValue }
        if let onboardingComplete { profile.onboardingComplete = onboardingComplete }
        try? modelContext?.save()
        recompute()
        scheduleReminders()
    }

    func scheduleReminders() {
        guard let profile, profile.onboardingComplete else { return }
        NotificationRouter.shared.requestPermission()
        ReminderScheduler.schedule(deadlines: deadlines, taxYear: config.taxYear)
    }

    private func persistWidgetSnapshot() {
        let defaults = UserDefaults(suiteName: "group.com.zzoutuo.QuarterSafe")
        defaults?.set(jarProgress, forKey: "jarProgress")
        defaults?.set(Money.text(result.requiredTotal), forKey: "jarAmountText")
        defaults?.set(nextDue?.date.timeIntervalSince1970 ?? 0, forKey: "nextDueTimestamp")
        defaults?.set(nextDue?.quarter.key ?? "", forKey: "nextDueQuarterKey")
        WidgetRefresher.reloadAll()
    }
}

enum WidgetRefresher {
    static func reloadAll() {
        WidgetCenterBridge.reloadTimelines()
    }
}

enum WidgetCenterBridge {
    static func reloadTimelines() {
        WidgetKitBridge.reload()
    }
}
