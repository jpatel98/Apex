import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showOnboarding = false
    @State private var selectedTab = 1
    @State private var previousTab = 0
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var body: some View {
        Group {
            if currentUser != nil {
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(0)
                    
                    LogEntryView(selectedTab: $selectedTab)
                        .tabItem {
                            Label("Log", systemImage: "plus.circle.fill")
                        }
                        .tag(1)
                    
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                        .tag(2)
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                        .tag(3)
                }
                .onChange(of: selectedTab) { oldValue, newValue in
                    if oldValue != newValue {
                        // Haptic feedback
                        let impact = UISelectionFeedbackGenerator()
                        impact.selectionChanged()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                OnboardingView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentUser != nil)
        .onAppear {
            checkOnboardingStatus()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView()
        }
    }
    
    private func checkOnboardingStatus() {
        if users.isEmpty || currentUser == nil {
            showOnboarding = true
        }
    }
}