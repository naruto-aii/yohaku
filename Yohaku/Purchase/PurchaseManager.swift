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
    private(set) var packProducts: [Product] = []
    private(set) var isLoading = true
    private(set) var isPurchasing = false
    private(set) var buyingPack: String?
    var statusNote: String?
    var packNote: String?

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
        let ids = [ProductID.lifetime] + DropPack.allCases.map(\.rawValue)
        do {
            let products = try await Product.products(for: ids)
            product = products.first { $0.id == ProductID.lifetime }
            packProducts = products.filter { DropPack.matching($0.id) != nil }
        } catch {
            product = nil
            packProducts = []
        }
        await refreshEntitlements()
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

    func priceText(for pack: DropPack) -> String {
        packProducts.first { $0.id == pack.rawValue }?.displayPrice ?? Copy.priceUnavailable
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

    func purchase(pack: DropPack) async {
        guard buyingPack == nil, let product = packProducts.first(where: { $0.id == pack.rawValue }) else { return }
        buyingPack = pack.rawValue
        defer { buyingPack = nil }
        packNote = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                await accept(transaction)
                packNote = Copy.received(Copy.drops)
            case .userCancelled:
                break
            case .pending:
                packNote = Copy.purchasePending
            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            return
        } catch {
            packNote = Copy.purchaseFailed
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
        if DropPack.matching(transaction.productID) != nil {
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
