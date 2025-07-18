import StoreKit
import SwiftUI

// Premium Features
enum PremiumFeature: String, CaseIterable {
    case unlimitedHistory = "unlimited_history"
    case advancedAnalytics = "advanced_analytics"
    case customNotifications = "custom_notifications"
    case exportData = "export_data"
    case multipleProfiles = "multiple_profiles"
    case appleWatch = "apple_watch"
    case widgets = "widgets"
    
    var displayName: String {
        switch self {
        case .unlimitedHistory: return "Unlimited History"
        case .advancedAnalytics: return "Advanced Analytics"
        case .customNotifications: return "Custom Notifications"
        case .exportData: return "Export Data"
        case .multipleProfiles: return "Multiple Profiles"
        case .appleWatch: return "Apple Watch App"
        case .widgets: return "Home Screen Widgets"
        }
    }
    
    var description: String {
        switch self {
        case .unlimitedHistory: return "View your complete caffeine history beyond 7 days"
        case .advancedAnalytics: return "Detailed insights and consumption patterns"
        case .customNotifications: return "Set custom alert times and messages"
        case .exportData: return "Export your data as CSV or JSON"
        case .multipleProfiles: return "Track caffeine for family members"
        case .appleWatch: return "Track caffeine from your wrist"
        case .widgets: return "Quick logging from your home screen"
        }
    }
}

// Subscription Tiers
enum SubscriptionTier: String, CaseIterable {
    case free = "free"
    case pro = "apex_pro_monthly"
    case premium = "apex_premium_yearly"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Apex Pro"
        case .premium: return "Apex Premium"
        }
    }
    
    var price: String {
        switch self {
        case .free: return "Free"
        case .pro: return "$4.99/month"
        case .premium: return "$39.99/year"
        }
    }
    
    var features: [PremiumFeature] {
        switch self {
        case .free:
            return []
        case .pro:
            return [.unlimitedHistory, .customNotifications, .exportData]
        case .premium:
            return PremiumFeature.allCases
        }
    }
}

@MainActor
class StoreManager: ObservableObject {
    static let shared = StoreManager()
    
    @Published var currentTier: SubscriptionTier = .free
    @Published var products: [Product] = []
    @Published var purchasedProductIDs: Set<String> = []
    @Published var isLoading = false
    @Published var purchaseError: String?
    
    private var updateListenerTask: Task<Void, Error>?
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // Check if user has access to a feature
    func hasAccess(to feature: PremiumFeature) -> Bool {
        return currentTier.features.contains(feature)
    }
    
    // Request products from App Store
    @MainActor
    func requestProducts() async {
        isLoading = true
        do {
            let productIDs = ["apex_pro_monthly", "apex_premium_yearly"]
            products = try await Product.products(for: productIDs)
            isLoading = false
        } catch {
            print("Failed to load products: \(error)")
            purchaseError = "Failed to load products"
            isLoading = false
        }
    }
    
    // Purchase a subscription
    @MainActor
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateCustomerProductStatus()
            await transaction.finish()
            
        case .userCancelled:
            break
            
        case .pending:
            break
            
        @unknown default:
            break
        }
    }
    
    // Restore purchases
    @MainActor
    func restorePurchases() async {
        try? await AppStore.sync()
        await updateCustomerProductStatus()
    }
    
    // Update current subscription status
    @MainActor
    private func updateCustomerProductStatus() async {
        var purchasedProducts: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchasedProducts.append(product)
                }
            } catch {
                print("Transaction verification failed")
            }
        }
        
        // Update tier based on active subscriptions
        if purchasedProducts.contains(where: { $0.id == "apex_premium_yearly" }) {
            currentTier = .premium
        } else if purchasedProducts.contains(where: { $0.id == "apex_pro_monthly" }) {
            currentTier = .pro
        } else {
            currentTier = .free
        }
        
        purchasedProductIDs = Set(purchasedProducts.map { $0.id })
    }
    
    // Listen for transaction updates
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateCustomerProductStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    // Verify transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}