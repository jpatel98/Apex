import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaffeineEntry.timestamp, order: .reverse) private var allEntries: [CaffeineEntry]
    @StateObject private var storeManager = StoreManager.shared
    
    @State private var selectedDate = Date()
    @State private var showPaywall = false
    
    var entries: [CaffeineEntry] {
        // Free users only see last 7 days
        if !storeManager.hasAccess(to: .unlimitedHistory) {
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return allEntries.filter { $0.timestamp >= sevenDaysAgo }
        }
        return allEntries
    }
    
    var groupedEntries: [Date: [CaffeineEntry]] {
        Dictionary(grouping: entries) { entry in
            Calendar.current.startOfDay(for: entry.timestamp)
        }
    }
    
    var sortedDates: [Date] {
        groupedEntries.keys.sorted(by: >)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Premium Banner for Free Users
                if !storeManager.hasAccess(to: .unlimitedHistory) {
                    PremiumBanner(
                        message: "📈 Unlock unlimited history",
                        description: "See all your caffeine data beyond 7 days"
                    ) {
                        showPaywall = true
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                List {
                    ForEach(sortedDates, id: \.self) { date in
                        Section(header: Text(dateHeader(for: date))) {
                            ForEach(groupedEntries[date] ?? [], id: \.id) { entry in
                                EntryRow(entry: entry) {
                                    deleteEntry(entry)
                                }
                            }
                        }
                    }
                    
                    // Premium prompt at bottom for free users
                    if !storeManager.hasAccess(to: .unlimitedHistory) && !sortedDates.isEmpty {
                        Section {
                            VStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                                
                                Text("Unlock Full History")
                                    .font(.headline)
                                
                                Text("Upgrade to see all your caffeine data")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Upgrade Now") {
                                    showPaywall = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
    
    private func dateHeader(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return date.formatted(date: .abbreviated, time: .omitted)
        }
    }
    
    private func deleteEntry(_ entry: CaffeineEntry) {
        modelContext.delete(entry)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete entry: \(error)")
        }
    }
}

struct EntryRow: View {
    let entry: CaffeineEntry
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            Image(systemName: iconForDrink(entry.drinkName))
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.drinkName)
                    .font(.body)
                Text("\(Int(entry.caffeineAmountMg))mg")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(entry.timestamp, format: .dateTime.hour().minute())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Entry", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this entry?")
        }
    }
    
    func iconForDrink(_ name: String) -> String {
        if let preset = DrinkPreset.presets.first(where: { $0.name == name }) {
            return preset.icon
        }
        return "cup.and.saucer"
    }
}

struct PremiumBanner: View {
    let message: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(message)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.accentColor)
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}