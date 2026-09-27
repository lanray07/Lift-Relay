import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class SubscriptionStore {
    static let productIDs = ["com.liftrelay.pro.monthly", "com.liftrelay.pro.annual"]
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var errorMessage: String?
    var isLoading = false
    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    var isPro: Bool { !purchasedProductIDs.intersection(Self.productIDs).isEmpty }

    func prepare() async {
        startObservingTransactions()
        isLoading = true
        defer { isLoading = false }
        do {
            products = try await Product.products(for: Self.productIDs).sorted { $0.price < $1.price }
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            if case .success(let verification) = result {
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func restore() async {
        do { try await AppStore.sync(); await refreshEntitlements() }
        catch { errorMessage = error.localizedDescription }
    }

    private func refreshEntitlements() async {
        var active: Set<String> = []
        for await result in Transaction.currentEntitlements {
            if let transaction = try? verified(result),
               Self.productIDs.contains(transaction.productID),
               transaction.revocationDate == nil,
               transaction.expirationDate.map({ $0 > .now }) ?? true {
                active.insert(transaction.productID)
            }
        }
        purchasedProductIDs = active
    }

    private func startObservingTransactions() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, let transaction = try? self.verified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result { case .verified(let value): value; case .unverified: throw StoreError.failedVerification }
    }

    enum StoreError: Error { case failedVerification }
}
