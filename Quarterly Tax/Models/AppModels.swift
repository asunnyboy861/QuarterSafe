import Foundation
import SwiftData

@Model
final class IncomeEvent {
    var id: UUID = UUID()
    var amountText: String = "0"
    var date: Date = Date.now
    var clientName: String = ""
    var createdAt: Date = Date.now
    var isDeleted: Bool = false

    init(amount: Decimal, date: Date = Date.now, clientName: String = "") {
        self.id = UUID()
        self.amountText = NSDecimalNumber(decimal: amount).stringValue
        self.date = date
        self.clientName = clientName
        self.createdAt = .now
    }

    var amount: Decimal { Money.parse(amountText) ?? 0 }
}

@Model
final class ExpenseEvent {
    var id: UUID = UUID()
    var amountText: String = "0"
    var date: Date = Date.now
    var note: String = ""
    var createdAt: Date = Date.now
    var isDeleted: Bool = false

    init(amount: Decimal, date: Date = Date.now, note: String = "") {
        self.id = UUID()
        self.amountText = NSDecimalNumber(decimal: amount).stringValue
        self.date = date
        self.note = note
        self.createdAt = .now
    }

    var amount: Decimal { Money.parse(amountText) ?? 0 }
}

@Model
final class Payment {
    var id: UUID = UUID()
    var quarterRaw: String = "Q1"
    var taxYear: Int = 2026
    var amountText: String = "0"
    var paidAt: Date = Date.now
    var method: String = PaymentMethod.irsDirectPay.rawValue
    var confirmationNumber: String = ""
    var proofPhotoData: Data?
    var note: String = ""

    init(quarter: Quarter, taxYear: Int, amount: Decimal, paidAt: Date = Date.now,
         method: String, confirmationNumber: String = "", proofPhotoData: Data? = nil, note: String = "") {
        self.id = UUID()
        self.quarterRaw = quarter.key
        self.taxYear = taxYear
        self.amountText = NSDecimalNumber(decimal: amount).stringValue
        self.paidAt = paidAt
        self.method = method
        self.confirmationNumber = confirmationNumber
        self.proofPhotoData = proofPhotoData
        self.note = note
    }

    var quarter: Quarter { Quarter(rawValue: quarterRaw) ?? .q1 }
    var amount: Decimal { Money.parse(amountText) ?? 0 }
}

@Model
final class Profile {
    var stateCode: String = "TX"
    var filingStatusRaw: String = FilingStatus.single.rawValue
    var priorYearTotalTaxText: String = ""
    var priorYearAGIText: String = ""
    var incomeRhythmRaw: String = IncomeRhythm.sideHustle.rawValue
    var simpleMode: Bool = true
    var onboardingComplete: Bool = false
    var reservedJarBalanceText: String = "0"

    init() {}

    var filingStatus: FilingStatus { FilingStatus(rawValue: filingStatusRaw) ?? .single }
    var incomeRhythm: IncomeRhythm { IncomeRhythm(rawValue: incomeRhythmRaw) ?? .sideHustle }
    var priorYearTotalTax: Decimal? {
        guard let v = Money.parse(priorYearTotalTaxText), v > 0 else { return nil }
        return v
    }
    var priorYearAGI: Decimal? {
        guard let v = Money.parse(priorYearAGIText), v > 0 else { return nil }
        return v
    }
    var reservedJarBalance: Decimal { Money.parse(reservedJarBalanceText) ?? 0 }
}
