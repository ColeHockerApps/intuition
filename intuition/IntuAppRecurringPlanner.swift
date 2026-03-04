import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppRecurringPlanner: ObservableObject {

    enum Frequency: String, Codable, CaseIterable {
        case daily
        case weekly
        case monthly
        case yearly
    }

    struct RecurringItem: Identifiable, Codable, Hashable {
        let id: UUID

        var title: String
        var amount: Decimal
        var currencyCode: String

        var categoryId: UUID?
        var note: String?

        var frequency: Frequency
        var interval: Int

        var startDate: Date
        var endDate: Date?

        var isExpense: Bool
        var isEnabled: Bool

        var lastAppliedAt: Date?

        init(
            id: UUID = UUID(),
            title: String,
            amount: Decimal,
            currencyCode: String,
            categoryId: UUID? = nil,
            note: String? = nil,
            frequency: Frequency,
            interval: Int = 1,
            startDate: Date,
            endDate: Date? = nil,
            isExpense: Bool,
            isEnabled: Bool = true,
            lastAppliedAt: Date? = nil
        ) {
            self.id = id
            self.title = title
            self.amount = amount
            self.currencyCode = currencyCode
            self.categoryId = categoryId
            self.note = note
            self.frequency = frequency
            self.interval = max(1, interval)
            self.startDate = startDate
            self.endDate = endDate
            self.isExpense = isExpense
            self.isEnabled = isEnabled
            self.lastAppliedAt = lastAppliedAt
        }
    }

    @Published private(set) var items: [RecurringItem] = []

    private let storeKey = "intu.recurring.items.v1"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        encoder.dateEncodingStrategy = .millisecondsSince1970
        decoder.dateDecodingStrategy = .millisecondsSince1970
        load()
    }

    // MARK: - CRUD

    func setItems(_ newItems: [RecurringItem]) {
        items = newItems
        persist()
    }

    func add(_ item: RecurringItem) {
        items.append(item)
        persist()
    }

    func update(_ item: RecurringItem) {
        guard let ix = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[ix] = item
        persist()
    }

    func remove(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    func toggle(id: UUID) {
        guard let ix = items.firstIndex(where: { $0.id == id }) else { return }
        items[ix].isEnabled.toggle()
        persist()
    }

    func resetAll() {
        items = []
        UserDefaults.standard.removeObject(forKey: storeKey)
    }

    // MARK: - Planning

    func dueItems(upTo date: Date) -> [RecurringItem] {
        let now = date
        return items
            .filter { $0.isEnabled }
            .filter { isItemActive($0, at: now) }
            .filter { isDue($0, by: now) }
            .sorted { ($0.nextDueDate(after: $0.lastAppliedAt ?? $0.startDate) ?? $0.startDate) < ($1.nextDueDate(after: $1.lastAppliedAt ?? $1.startDate) ?? $1.startDate) }
    }

    func markApplied(id: UUID, at date: Date = Date()) {
        guard let ix = items.firstIndex(where: { $0.id == id }) else { return }
        items[ix].lastAppliedAt = date
        persist()
    }

    // MARK: - Internals

    private func isItemActive(_ item: RecurringItem, at date: Date) -> Bool {
        if date < item.startDate { return false }
        if let end = item.endDate, date > end { return false }
        return true
    }

    private func isDue(_ item: RecurringItem, by date: Date) -> Bool {
        let base = item.lastAppliedAt ?? item.startDate
        guard let next = item.nextDueDate(after: base) else { return false }
        return next <= date
    }

    private func persist() {
        do {
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: storeKey)
        } catch {
            // ignore
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storeKey) else {
            items = []
            return
        }
        do {
            items = try decoder.decode([RecurringItem].self, from: data)
        } catch {
            items = []
        }
    }
}

// MARK: - Recurring calculations

private extension IntuAppRecurringPlanner.RecurringItem {

    func nextDueDate(after date: Date) -> Date? {
        var cursor = max(date, startDate)

        // ensure cursor is strictly >= startDate
        if cursor < startDate { cursor = startDate }

        let cal = Calendar.current
        let step = max(1, interval)

        // compute next date by adding step until we move forward at least once
        var next: Date?

        switch frequency {
        case .daily:
            next = cal.date(byAdding: .day, value: step, to: cursor)
        case .weekly:
            next = cal.date(byAdding: .weekOfYear, value: step, to: cursor)
        case .monthly:
            next = cal.date(byAdding: .month, value: step, to: cursor)
        case .yearly:
            next = cal.date(byAdding: .year, value: step, to: cursor)
        }

        guard let n = next else { return nil }
        if let end = endDate, n > end { return nil }
        return n
    }
}
