import SwiftUI

struct AddIncomeSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = AppStore.shared
    @State private var amountText = ""
    @State private var clientName = ""
    @State private var showExpense = false
    @State private var expenseText = ""
    @State private var expenseNote = ""

    private var amount: Decimal? {
        Money.parse(amountText)
    }

    private var setAsideHint: Decimal? {
        guard let amount, amount > 0 else { return nil }
        return store.setAsideFor(amount: amount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 56, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                        Text("Amount received")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Amount received")

                    TextField("Client or source (optional)", text: $clientName)
                        .textFieldStyle(.roundedBorder)

                    if let hint = setAsideHint {
                        Label("This one: save \(Money.text(hint))", systemImage: "jar.fill")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.green.opacity(0.12)))
                    }

                    Button {
                        showExpense.toggle()
                    } label: {
                        Label("Log a deductible expense instead", systemImage: showExpense ? "minus.circle.fill" : "minus.circle")
                            .font(.subheadline)
                    }
                    .tint(.orange)

                    if showExpense {
                        VStack(spacing: 10) {
                            TextField("Expense amount", text: $expenseText)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                            TextField("What was it for? (optional)", text: $expenseNote)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text(showExpense && !expenseText.isEmpty ? "Save expense" : "Save income")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(!canSave)
                }
                .padding(20)
                .screenMaxWidth()
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var canSave: Bool {
        if showExpense, let exp = Money.parse(expenseText), exp > 0 {
            return true
        }
        if let amount, amount > 0 { return true }
        return false
    }

    private func save() {
        if showExpense, let exp = Money.parse(expenseText), exp > 0 {
            store.addExpense(amount: exp, note: expenseNote)
            dismiss()
            return
        }
        if let amount, amount > 0 {
            store.addIncome(amount: amount, clientName: clientName)
            dismiss()
        }
    }
}
