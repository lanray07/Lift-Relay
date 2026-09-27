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

    var isPro: Bool { !purchasedProductIDs.isEmpty }

    func prepare() async {
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
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
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
            if let transaction = try? verified(result), transaction.revocationDate == nil { active.insert(transaction.productID) }
        }
        purchasedProductIDs = active
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result { case .verified(let value): value; case .unverified: throw StoreError.failedVerification }
    }

    enum StoreError: Error { case failedVerification }
}
