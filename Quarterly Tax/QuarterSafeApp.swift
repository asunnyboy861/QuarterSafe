import SwiftUI
import SwiftData

@main
struct QuarterSafeApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: IncomeEvent.self, ExpenseEvent.self, Payment.self, Profile.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
                .onAppear {
                    AppStore.shared.attach(context: container.mainContext)
                    NotificationRouter.shared.start()
                    NotificationRouter.shared.onQuarterTapped = { quarter in
                        AppStore.shared.pendingDeepLinkQuarter = quarter
                    }
                    if AppStore.shared.profile?.onboardingComplete == true {
                        AppStore.shared.scheduleReminders()
                    }
                }
        }
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var store = AppStore.shared
    @State private var tab: Tab = .home

    enum Tab: Hashable {
        case home, calendar, payments, vault
    }

    var body: some View {
        ZStack {
            TabView(selection: $tab) {
                HomeView(onNavigate: { tab = $0 })
                    .tabItem { Label("Home", systemImage: "jar.fill") }
                    .tag(Tab.home)
                CalendarView()
                    .tabItem { Label("Calendar", systemImage: "calendar.badge.clock") }
                    .tag(Tab.calendar)
                PaymentsView()
                    .tabItem { Label("Payments", systemImage: "checkmark.seal.fill") }
                    .tag(Tab.payments)
                VaultView()
                    .tabItem { Label("Vault", systemImage: "lock.doc.fill") }
                    .tag(Tab.vault)
            }
            if store.showConfetti {
                ConfettiView(active: true) { store.showConfetti = false }
            }
        }
        .onAppear {
            if store.modelContext == nil {
                store.attach(context: modelContext)
            }
        }
        .onChange(of: store.pendingDeepLinkQuarter) { _, newValue in
            if let quarter = newValue {
                tab = .payments
                store.pendingDeepLinkQuarter = nil
                NotificationCenter.default.post(name: Notification.Name("openMarkPaid"), object: quarter)
            }
        }
        .fullScreenCover(isPresented: isOnboardingNeeded) {
            OnboardingView()
        }
    }

    private var isOnboardingNeeded: Binding<Bool> {
        Binding(
            get: { !(store.profile?.onboardingComplete ?? false) },
            set: { _ in })
    }
}

final class PaymentsRouter {
    static let shared = PaymentsRouter()
    var openMarkPaid: Quarter?
}
