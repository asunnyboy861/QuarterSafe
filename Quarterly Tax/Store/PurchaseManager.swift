import Foundation
import StoreKit
import Combine

@MainActor
final class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()

    @Published var isPro: Bool = false
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var loadError: String?

    private let lifetimeId = "com.zzoutuo.quartersafe.lifetime"
    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts(); await checkPurchased() }
    }

    func loadProducts() async {
        isLoading = true
        do {
            products = try await Product.products(for: [lifetimeId])
            loadError = nil
        } catch {
            loadError = "Unable to load purchase options."
        }
        isLoading = false
    }

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await checkPurchased()
                    await transaction.finish()
                    return true
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            loadError = "Purchase failed: \(error.localizedDescription)"
        }
        return false
    }

    func restorePurchases() async {
        do {
            try await StoreKit.AppStore.sync()
            await checkPurchased()
            loadError = nil
        } catch {
            loadError = "Restore failed: \(error.localizedDescription)"
        }
    }

    private func checkPurchased() async {
        guard let result = await Transaction.currentEntitlement(for: lifetimeId) else {
            isPro = false
            return
        }
        if case .verified(let transaction) = result {
            isPro = transaction.revocationDate == nil
        } else {
            isPro = false
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    Task { @MainActor [weak self] in
                        await self?.checkPurchased()
                    }
                }
            }
        }
    }

    var lifetimeProduct: Product? { products.first { $0.id == lifetimeId } }

    deinit {
        transactionListener?.cancel()
    }
}
