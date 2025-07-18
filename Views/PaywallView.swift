import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var storeManager = StoreManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTier: SubscriptionTier = .pro
    @State private var isProcessingPurchase = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color.blue.opacity(0.8), Color.purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 15) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                                .shadow(radius: 10)
                            
                            Text("Unlock Apex Premium")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Take control of your caffeine")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 40)
                        
                        // Features Grid
                        VStack(spacing: 20) {
                            FeatureRow(
                                icon: "infinity",
                                title: "Unlimited History",
                                description: "Track beyond 7 days"
                            )
                            
                            FeatureRow(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Advanced Analytics",
                                description: "Detailed consumption insights"
                            )
                            
                            FeatureRow(
                                icon: "bell.badge",
                                title: "Custom Notifications",
                                description: "Personalized crash alerts"
                            )
                            
                            FeatureRow(
                                icon: "square.and.arrow.up",
                                title: "Export Data",
                                description: "CSV and JSON exports"
                            )
                            
                            FeatureRow(
                                icon: "person.2.fill",
                                title: "Multiple Profiles",
                                description: "Track family caffeine"
                            )
                            
                            FeatureRow(
                                icon: "applewatch",
                                title: "Apple Watch App",
                                description: "Track from your wrist"
                            )
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Subscription Options
                        VStack(spacing: 15) {
                            ForEach([SubscriptionTier.pro, SubscriptionTier.premium], id: \.self) { tier in
                                SubscriptionOption(
                                    tier: tier,
                                    isSelected: selectedTier == tier,
                                    product: storeManager.products.first { $0.id == tier.rawValue }
                                ) {
                                    selectedTier = tier
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Purchase Button
                        Button(action: purchaseSelected) {
                            if isProcessingPurchase {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.green)
                                    .cornerRadius(15)
                            } else {
                                Text("Continue")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 60)
                                    .background(Color.green)
                                    .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        .disabled(isProcessingPurchase)
                        
                        // Restore Button
                        Button(action: restorePurchases) {
                            Text("Restore Purchases")
                                .font(.footnote)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Terms
                        VStack(spacing: 5) {
                            Text("Subscriptions auto-renew. Cancel anytime.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            
                            HStack(spacing: 20) {
                                Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                                Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                            }
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarItems(
                trailing: Button("Close") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
            .alert("Purchase Error", isPresented: .constant(storeManager.purchaseError != nil)) {
                Button("OK") {
                    storeManager.purchaseError = nil
                }
            } message: {
                Text(storeManager.purchaseError ?? "")
            }
        }
    }
    
    private func purchaseSelected() {
        guard let product = storeManager.products.first(where: { $0.id == selectedTier.rawValue }) else {
            return
        }
        
        isProcessingPurchase = true
        
        Task {
            do {
                try await storeManager.purchase(product)
                isProcessingPurchase = false
                dismiss()
            } catch {
                isProcessingPurchase = false
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            await storeManager.restorePurchases()
            if storeManager.currentTier != .free {
                dismiss()
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct SubscriptionOption: View {
    let tier: SubscriptionTier
    let isSelected: Bool
    let product: Product?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(tier.displayName)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if tier == .premium {
                            Text("BEST VALUE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(5)
                        }
                    }
                    
                    if let product = product {
                        Text(product.displayPrice)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if tier == .premium {
                            Text("Save 33%")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        Text(tier.price)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}