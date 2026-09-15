import SwiftUI

struct SettingsView: View {
    @State private var store = AppStore.shared
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var showPaywall = false
    @State private var showContact = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        List {
            disclaimerSection
            profileSection
            proSection
            dataSection
            legalSection
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .sheet(isPresented: $showContact) { ContactSupportView() }
    }

    private var disclaimerSection: some View {
        Section {
            Label("QuarterSafe provides estimates for planning only and is not tax advice. Verify with IRS Publication 505 / Form 1040-ES or a CPA.", systemImage: "exclamationmark.triangle")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var profileSection: some View {
        Section("Your profile") {
            Picker("State", selection: stateBinding) {
                ForEach(store.states) { state in
                    Text("\(state.name) (\(state.code))").tag(state.code)
                }
            }
            Picker("Filing status", selection: filingBinding) {
                ForEach(FilingStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            Picker("Income rhythm", selection: rhythmBinding) {
                ForEach(IncomeRhythm.allCases) { option in
                    Text(option.displayName).tag(option)
                }
            }
            priorTaxRow
            jarBalanceRow
        }
    }

    private var stateBinding: Binding<String> {
        Binding(get: { store.profile?.stateCode ?? "TX" },
                set: { store.updateProfile(stateCode: $0) })
    }

    private var filingBinding: Binding<FilingStatus> {
        Binding(get: { store.profile?.filingStatus ?? .single },
                set: { store.updateProfile(filingStatus: $0) })
    }

    private var rhythmBinding: Binding<IncomeRhythm> {
        Binding(get: { store.profile?.incomeRhythm ?? .sideHustle },
                set: { store.updateProfile(incomeRhythm: $0) })
    }

    @State private var priorTaxText = ""
    @State private var priorAGIText = ""
    @State private var jarText = ""

    private var priorTaxRow: some View {
        Group {
            TextField("Last year's total tax (1040 line 24)", text: $priorTaxText)
                .keyboardType(.decimalPad)
                .onSubmit { savePrior() }
            TextField("Last year's AGI (optional)", text: $priorAGIText)
                .keyboardType(.decimalPad)
                .onSubmit { savePrior() }
            Button("Save tax figures") { savePrior() }
                .font(.caption)
        }
        .onAppear {
            if let tax = store.profile?.priorYearTotalTax, priorTaxText.isEmpty {
                priorTaxText = NSDecimalNumber(decimal: tax).stringValue
            }
            if let agi = store.profile?.priorYearAGI, priorAGIText.isEmpty {
                priorAGIText = NSDecimalNumber(decimal: agi).stringValue
            }
        }
    }

    private var jarBalanceRow: some View {
        TextField("Money already in your tax jar", text: $jarText)
            .keyboardType(.decimalPad)
            .onSubmit {
                store.updateProfile(reservedBalance: .some(Money.parse(jarText) ?? 0))
            }
            .onAppear {
                if let v = store.profile?.reservedJarBalance, jarText.isEmpty, v > 0 {
                    jarText = NSDecimalNumber(decimal: v).stringValue
                }
            }
    }

    private func savePrior() {
        let tax = Money.parse(priorTaxText)
        let agi = Money.parse(priorAGIText)
        store.updateProfile(
            priorYearTax: tax == nil ? .none : .some(tax!),
            priorYearAGI: agi == nil ? .none : .some(agi!))
    }

    private var proSection: some View {
        Section {
            if purchaseManager.isPro {
                Label("Pro unlocked — thank you!", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro — $19.99 once", systemImage: "lock.open")
                }
            }
            Button {
                Task { await purchaseManager.restorePurchases() }
            } label: {
                Label("Restore Purchases", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Pro")
        } footer: {
            if let error = purchaseManager.loadError {
                Text(error).foregroundStyle(.red)
            }
        }
    }

    private var dataSection: some View {
        Section {
            HStack {
                Text("Tax tables")
                Spacer()
                Text("\(store.config.version) (rev \(store.config.reviewedDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Text("Storage")
                Spacer()
                Text("On this iPhone only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Data & tax tables")
        } footer: {
            Text("Tax tables are updated annually; always confirm deadlines on irs.gov. Tax rates for your state are simplified estimates.")
                .font(.caption2)
        }
    }

    private var legalSection: some View {
        Section("Legal & support") {
            Button {
                showContact = true
            } label: {
                Label("Contact Support", systemImage: "bubble.left.and.bubble.right")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/QuarterSafe/privacy.html")!) {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
            Link(destination: URL(string: "https://asunnyboy861.github.io/QuarterSafe/support.html")!) {
                Label("Support & FAQ", systemImage: "questionmark.circle")
            }
        }
    }

    private var aboutSection: some View {
        Section {
            Text(appVersion)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
