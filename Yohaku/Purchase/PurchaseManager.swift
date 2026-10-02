import Foundation
import Observation
import StoreKit

enum ProductID {
    static let lifetime = "yohaku_lifetime"
    static let seed = "yohaku_seed"
}

@MainActor
@Observable
final class PurchaseManager {
    private(set) var isUnlocked = false
    private(set) var product: Product?
    private(set) var seedProduct: Product?
    private(set) var isLoading = true
    private(set) var isPurchasing = false
    private(set) var isBuyingSeed = false
    var statusNote: String?
    var seedNote: String?

    @ObservationIgnored var onConsumable: ((UInt64, String) -> Void)?
    @ObservationIgnored private var updates: Task<Void, Never>?

    func startListening() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let transaction = try? self.verified(result) else { continue }
                await self.accept(transaction)
            }
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [ProductID.lifetime, ProductID.seed])
            product = products.first { $0.id == ProductID.lifetime }
            seedProduct = products.first { $0.id == ProductID.seed }
            await refreshEntitlements()
        } catch {
            product = nil
            seedProduct = nil
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
                await accept(transaction)
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

    func purchaseSeed() async {
        guard let seedProduct, !isBuyingSeed else { return }
        isBuyingSeed = true
        defer { isBuyingSeed = false }
        seedNote = nil
        do {
            let result = try await seedProduct.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await accept(transaction)
                seedNote = Copy.seedAdded
            case .userCancelled:
                break
            case .pending:
                seedNote = Copy.purchasePending
            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            return
        } catch {
            seedNote = Copy.purchaseFailed
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

    private func accept(_ transaction: Transaction) async {
        if transaction.productID == ProductID.seed {
            onConsumable?(transaction.id, transaction.productID)
        }
        await transaction.finish()
        if transaction.productID == ProductID.lifetime {
            await refreshEntitlements()
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
