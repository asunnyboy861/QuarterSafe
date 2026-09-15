import SwiftUI

struct OnboardingView: View {
    @State private var store = AppStore.shared
    @State private var step = 0
    @State private var stateCode = "TX"
    @State private var priorTaxText = ""
    @State private var priorAGIText = ""
    @State private var rhythm: IncomeRhythm = .sideHustle
    @State private var filingStatus: FilingStatus = .single

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: Double(step + 1), total: 4)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                TabView(selection: $step) {
                    stateStep.tag(0)
                    priorYearStep.tag(1)
                    rhythmStep.tag(2)
                    disclaimerStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(.systemBackground))
        }
        .interactiveDismissDisabled()
    }

    private var stateStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Welcome to QuarterSafe")
                    .font(.largeTitle.bold())
                Text("Your quarterly tax copilot. Three quick questions and you'll see exactly how much to set aside.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Text("Which state do you live in?")
                    .font(.headline)
                Picker("State", selection: $stateCode) {
                    ForEach(store.states) { state in
                        Text("\(state.name) (\(state.code))").tag(state.code)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 160)
                Spacer(minLength: 16)
                nextButton { step = 1 }
            }
            .padding(24)
            .screenMaxWidth()
        }
    }

    private var priorYearStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How much tax did you owe last year?")
                    .font(.title.bold())
                Text("Your 1040 line 24 total. Skip this and we'll use a simple 30% estimate instead.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("Last year's total tax, e.g. 12000", text: $priorTaxText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                TextField("Last year's AGI (optional)", text: $priorAGIText)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                Picker("Filing status", selection: $filingStatus) {
                    ForEach(FilingStatus.allCases) { status in
                        Text(status.displayName).tag(status)
                    }
                }
                .pickerStyle(.segmented)
                HStack(spacing: 12) {
                    Button("Back") { step = 0 }
                        .buttonStyle(.bordered)
                    Button("Skip for now") { rhythm = .sideHustle; finishPriorYear() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Spacer()
                    if !priorTaxText.isEmpty {
                        Button("Next") { finishPriorYear() }
                            .buttonStyle(.borderedProminent)
                            .tint(.green)
                    }
                }
            }
            .padding(24)
            .screenMaxWidth()
        }
    }

    private var rhythmStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("How do you earn?")
                    .font(.title.bold())
                Text("This sets your default reserve rate.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                ForEach(IncomeRhythm.allCases) { option in
                    Button {
                        rhythm = option
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(option.displayName).font(.headline).foregroundStyle(.primary)
                                Text("Default reserve: \(Int(option.defaultReserveRate * 100))%")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if rhythm == option {
                                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.secondarySystemBackground)))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(rhythm == option ? Color.green : .clear, lineWidth: 2))
                    }
                    .accessibilityLabel(option.displayName)
                }
                HStack(spacing: 12) {
                    Button("Back") { step = 1 }
                        .buttonStyle(.bordered)
                    Spacer()
                    Button("Done") { step = 3 }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                }
            }
            .padding(24)
            .screenMaxWidth()
        }
    }

    private var disclaimerStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                Text("You're all set!")
                    .font(.largeTitle.bold())
                Text("QuarterSafe provides estimates for planning only and is not tax advice. Verify with IRS Publication 505 / Form 1040-ES or a CPA.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                Text("Everything stays on this iPhone.")
                    .font(.footnote.bold())
                    .foregroundStyle(.green)
                Button {
                    finishOnboarding()
                } label: {
                    Text("Start tracking")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .padding(24)
            .screenMaxWidth()
        }
    }

    private func nextButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
    }

    private func finishPriorYear() {
        if let tax = Money.parse(priorTaxText), tax > 0 {
            store.updateProfile(priorYearTax: .some(tax), priorYearAGI: priorAGIText.isEmpty ? .none : .some(Money.parse(priorAGIText) ?? 0))
        }
        step = 2
    }

    private func finishOnboarding() {
        store.updateProfile(
            stateCode: stateCode,
            filingStatus: filingStatus,
            incomeRhythm: rhythm,
            onboardingComplete: true)
        store.scheduleReminders()
        step = 3
    }
}
