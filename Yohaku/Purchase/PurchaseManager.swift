import Foundation
import Observation
import StoreKit

enum ProductID {
    static let lifetime = "yohaku_lifetime"
}

@MainActor
@Observable
final class PurchaseManager {
    private(set) var isUnlocked = false
    private(set) var product: Product?
    private(set) var isLoading = true
    private(set) var isPurchasing = false
    var statusNote: String?

    @ObservationIgnored private var updates: Task<Void, Never>?

    func startListening() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.verified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [ProductID.lifetime])
            product = products.first { $0.id == ProductID.lifetime }
            await refreshEntitlements()
        } catch {
            product = nil
        }
    }

    func refreshEntitlements() async {
        var unlocked = false
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verified(result) else { continue }
            guard transaction.productID == ProductID.lifetime else { continue }
            guard transaction.revocationDate == nil else { continue }
            unlocked = true
        }
        isUnlocked = unlocked
    }

    func purchase() async {
        guard let product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        statusNote = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                statusNote = Copy.purchasePending
            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            return
        } catch {
            statusNote = Copy.purchaseFailed
        }
    }

    func restore() async {
        guard !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        statusNote = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            statusNote = isUnlocked ? Copy.restored : Copy.nothingToRestore
        } catch StoreKitError.userCancelled {
            return
        } catch {
            statusNote = Copy.purchaseFailed
        }
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.unverified
        case .verified(let value):
            return value
        }
    }
}

private enum PurchaseError: Error {
    case unverified
}
