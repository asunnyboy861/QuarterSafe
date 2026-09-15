import SwiftUI

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss

    enum Subject: String, CaseIterable, Identifiable {
        case general = "General"
        case feature = "Feature Suggestion"
        case bug = "Bug Report"
        case usage = "Usage Question"
        case performance = "Performance Issue"
        case ui = "UI Improvement"
        case other = "Other"

        var id: String { rawValue }

        var symbol: String {
            switch self {
            case .general: "bubble.left.fill"
            case .feature: "lightbulb.fill"
            case .bug: "ant.fill"
            case .usage: "questionmark.circle.fill"
            case .performance: "gauge.with.dots.needle.67percent"
            case .ui: "paintpalette.fill"
            case .other: "ellipsis.circle.fill"
            }
        }
    }

    @State private var subject: Subject = .general
    @State private var customSubject = ""
    @State private var name = ""
    @State private var email = ""
    @State private var message = ""
    @State private var isSubmitting = false
    @State private var resultFeedback: FeedbackResult?

    enum FeedbackResult {
        case success
        case error(String)
    }

    private let backendURL = URL(string: "https://feedback-board.iocompile67692.workers.dev/api/feedback")!

    private var emailValid: Bool {
        email.contains("@") && email.contains(".") && email.count > 4
    }

    private var canSubmit: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && emailValid
            && !message.trimmingCharacters(in: .whitespaces).isEmpty
            && (subject != .other || !customSubject.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private var resolvedSubject: String {
        subject == .other ? customSubject.trimmingCharacters(in: .whitespaces) : subject.rawValue
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    subjectGrid
                    if subject == .other {
                        TextField("Tell us the topic", text: $customSubject)
                            .textFieldStyle(.roundedBorder)
                    }
                    TextField("Your name", text: $name)
                        .textFieldStyle(.roundedBorder)
                    TextField("yourname@example.com", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                    if !email.isEmpty && !emailValid {
                        Text("Please enter a valid email address.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .overlay(alignment: .topLeading) {
                                if message.isEmpty {
                                    Text("Tell us what's on your mind...")
                                        .font(.body)
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 8)
                                        .padding(.leading, 4)
                                        .allowsHitTesting(false)
                                }
                            }
                            .onChange(of: message) { _, newValue in
                                if newValue.count > 1000 {
                                    message = String(newValue.prefix(1000))
                                }
                            }
                        Text("\(message.count) / 1000")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    submitButton
                    if let result = resultFeedback {
                        feedbackBanner(result)
                    }
                    Text("We only use your email to respond to this feedback.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(20)
                .screenMaxWidth()
            }
            .background(Color(.systemBackground))
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var subjectGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            ForEach(Subject.allCases) { option in
                subjectTile(option)
            }
        }
    }

    private func subjectTile(_ option: Subject) -> some View {
        let selected = subject == option
        return Button {
            subject = option
        } label: {
            VStack(spacing: 6) {
                Image(systemName: option.symbol)
                    .font(.title3)
                Text(option.rawValue)
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? Color.green : Color(.secondarySystemBackground)))
            .foregroundStyle(selected ? Color.white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? Color.green : Color(.separator), lineWidth: selected ? 2 : 1))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.white)
                        .padding(6)
                }
            }
            .scaleEffect(selected ? 1.02 : 1)
        }
        .accessibilityLabel("\(option.rawValue) subject\(selected ? ", selected" : "")")
    }

    private var submitButton: some View {
        Button {
            submit()
        } label: {
            HStack {
                if isSubmitting {
                    ProgressView().tint(.white)
                } else {
                    Text("Submit")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .disabled(!canSubmit || isSubmitting)
    }

    private func feedbackBanner(_ result: FeedbackResult) -> some View {
        HStack {
            switch result {
            case .success:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("Thank you! Your feedback has been sent.").font(.subheadline)
            case .error(let text):
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.red)
                Text(text).font(.subheadline)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .transition(.opacity)
    }

    private func submit() {
        isSubmitting = true
        resultFeedback = nil
        let payload = FeedbackRequest(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            subject: resolvedSubject,
            message: message.trimmingCharacters(in: .whitespaces),
            app_name: "QuarterSafe")

        var request = URLRequest(url: backendURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        request.httpBody = try? JSONEncoder().encode(payload)

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error {
                    resultFeedback = .error("Something went wrong. Please try again. (\(error.localizedDescription))")
                    return
                }
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                    resultFeedback = .error("Something went wrong. Please try again.")
                    return
                }
                resultFeedback = .success
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    dismiss()
                }
            }
        }.resume()
    }
}

struct FeedbackRequest: Codable {
    let name: String
    let email: String
    let subject: String
    let message: String
    let app_name: String
}
