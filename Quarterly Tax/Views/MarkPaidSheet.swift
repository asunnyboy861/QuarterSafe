import SwiftUI
import PhotosUI

struct MarkPaidSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store = AppStore.shared
    var quarter: Quarter

    @State private var amountText = ""
    @State private var method: PaymentMethod = .irsDirectPay
    @State private var confirmationNumber = ""
    @State private var note = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 6) {
                        Text("How much did you pay for \(quarter.key)?")
                            .font(.headline)
                        TextField("0", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .monospacedDigit()
                            .textFieldStyle(.plain)
                        Text("Due date: \(store.deadlines[quarter]?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Text("Payment method")
                        .font(.headline)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(PaymentMethod.allCases) { m in
                            methodChip(m)
                        }
                    }

                    TextField("Confirmation # (optional)", text: $confirmationNumber)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()

                    TextField("Note (optional)", text: $note)
                        .textFieldStyle(.roundedBorder)

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoData == nil ? "Attach proof photo (optional)" : "Proof photo attached ✓",
                              systemImage: photoData == nil ? "camera" : "photo.fill")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .onChange(of: photoItem) { _, item in
                        guard let item else { return }
                        Task {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                photoData = compress(data)
                            }
                        }
                    }

                    Button {
                        save()
                    } label: {
                        Text("Save payment")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled((Money.parse(amountText) ?? 0) <= 0)

                    Text("Your proof stays on this device and in your exported PDF only.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .screenMaxWidth()
            }
            .navigationTitle("Mark as Paid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if amountText.isEmpty {
                    let remaining = max(0, store.result.requiredTotal / 4 - (store.paymentsByQuarter[quarter] ?? 0))
                    amountText = remaining > 0 ? NSDecimalNumber(decimal: remaining).stringValue : ""
                }
            }
        }
    }

    private func methodChip(_ m: PaymentMethod) -> some View {
        Button {
            method = m
        } label: {
            HStack {
                if method == m {
                    Image(systemName: "checkmark.circle.fill")
                }
                Text(m.rawValue)
                    .font(.subheadline)
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(method == m ? Color.green.opacity(0.15) : Color(.tertiarySystemFill)))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(method == m ? Color.green : .clear, lineWidth: 2))
            .foregroundStyle(.primary)
        }
        .accessibilityLabel("Payment method \(m.rawValue)")
    }

    private func compress(_ data: Data) -> Data {
        guard let image = UIImage(data: data) else { return data }
        let maxDim: CGFloat = 1400
        let scale = min(1, maxDim / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        return resized.jpegData(compressionQuality: 0.6) ?? data
    }

    private func save() {
        guard let amount = Money.parse(amountText), amount > 0 else { return }
        store.markPaid(
            quarter: quarter,
            amount: amount,
            method: method,
            confirmationNumber: confirmationNumber,
            proofPhotoData: photoData,
            note: note)
        dismiss()
    }
}
