import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @State private var showOnboarding = false
    
    var currentUser: User? {
        users.first(where: { $0.isOnboarded })
    }
    
    var body: some View {
        Group {
            if currentUser != nil {
                TabView {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "chart.line.uptrend.xyaxis")
                        }
                    
                    LogEntryView()
                        .tabItem {
                            Label("Log", systemImage: "plus.circle.fill")
                        }
                    
                    HistoryView()
                        .tabItem {
                            Label("History", systemImage: "clock")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
            } else {
                OnboardingView()
            }
        }
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