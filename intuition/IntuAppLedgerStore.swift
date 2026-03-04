import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppLedgerStore: ObservableObject {

    struct Entry: Identifiable, Codable, Hashable {
        let id: UUID
        var title: String
        var amount: Double
        var category: String
        var date: Date
        var note: String?

        init(
            id: UUID = UUID(),
            title: String,
            amount: Double,
            category: String,
            date: Date = Date(),
            note: String? = nil
        ) {
            self.id = id
            self.title = title
            self.amount = amount
            self.category = category
            self.date = date
            self.note = note
        }
    }

    @Published private(set) var entries: [Entry] = []

    private let storageKey = "intuapp.ledger.entries"

    init() {
        load()
    }

    // MARK: - CRUD

    func addEntry(
        title: String,
        amount: Double,
        category: String,
        date: Date = Date(),
        note: String? = nil
    ) {
        let entry = Entry(
            title: title,
            amount: amount,
            category: category,
            date: date,
            note: note
        )

        entries.insert(entry, at: 0)
        save()
    }

    func updateEntry(_ entry: Entry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        save()
    }

    func deleteEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func clearAll() {
        entries.removeAll()
        save()
    }

    // MARK: - Queries

    func totalBalance() -> Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    func totalForCategory(_ category: String) -> Double {
        entries
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.amount }
    }

    func entries(forMonth month: Int, year: Int) -> [Entry] {
        entries.filter {
            let comps = Calendar.current.dateComponents([.month, .year], from: $0.date)
            return comps.month == month && comps.year == year
        }
    }

    func recent(limit: Int = 10) -> [Entry] {
        Array(entries.prefix(limit))
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch { }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Entry].self, from: data)
        else {
            entries = []
            return
        }

        entries = decoded.sorted { $0.date > $1.date }
    }
}
