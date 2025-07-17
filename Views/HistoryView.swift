import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CaffeineEntry.timestamp, order: .reverse) private var entries: [CaffeineEntry]
    
    @State private var selectedDate = Date()
    
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
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
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