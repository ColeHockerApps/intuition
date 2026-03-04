import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppBudgetEngine: ObservableObject {

    struct CategoryBudget: Identifiable, Codable, Hashable {
        let id: UUID
        var category: String
        var monthlyLimit: Double

        init(id: UUID = UUID(), category: String, monthlyLimit: Double) {
            self.id = id
            self.category = category
            self.monthlyLimit = monthlyLimit
        }
    }

    struct MonthSummary: Equatable {
        var month: Int
        var year: Int
        var income: Double
        var expense: Double
        var net: Double { income + expense }
    }

    @Published private(set) var budgets: [CategoryBudget] = []
    @Published private(set) var monthSummary: MonthSummary = MonthSummary(
        month: Calendar.current.component(.month, from: Date()),
        year: Calendar.current.component(.year, from: Date()),
        income: 0,
        expense: 0
    )

    private let storageKey = "intuapp.budget.categories"

    init() {
        load()
    }

    // MARK: - Budgets

    func upsertBudget(category: String, monthlyLimit: Double) {
        if let idx = budgets.firstIndex(where: { $0.category == category }) {
            budgets[idx].monthlyLimit = monthlyLimit
        } else {
            budgets.append(CategoryBudget(category: category, monthlyLimit: monthlyLimit))
        }
        budgets.sort { $0.category.localizedCaseInsensitiveCompare($1.category) == .orderedAscending }
        save()
    }

    func removeBudget(category: String) {
        budgets.removeAll { $0.category == category }
        save()
    }

    func limit(for category: String) -> Double? {
        budgets.first(where: { $0.category == category })?.monthlyLimit
    }

    func clearAll() {
        budgets.removeAll()
        save()
    }

    // MARK: - Analytics

    func recalc(using ledger: IntuAppLedgerStore, month: Int, year: Int) {
        let list = ledger.entries(forMonth: month, year: year)

        var income: Double = 0
        var expense: Double = 0

        for e in list {
            if e.amount >= 0 {
                income += e.amount
            } else {
                expense += e.amount
            }
        }

        monthSummary = MonthSummary(
            month: month,
            year: year,
            income: income,
            expense: expense
        )
    }

    func spent(for category: String, using ledger: IntuAppLedgerStore, month: Int, year: Int) -> Double {
        let list = ledger.entries(forMonth: month, year: year)
        let sum = list
            .filter { $0.category == category }
            .reduce(0.0) { $0 + $1.amount }

        return min(0.0, sum)
    }

    func remaining(for category: String, using ledger: IntuAppLedgerStore, month: Int, year: Int) -> Double? {
        guard let lim = limit(for: category) else { return nil }
        let s = spent(for: category, using: ledger, month: month, year: year)
        return lim + s
    }

    func usageRatio(for category: String, using ledger: IntuAppLedgerStore, month: Int, year: Int) -> Double? {
        guard let lim = limit(for: category), lim > 0 else { return nil }
        let s = abs(spent(for: category, using: ledger, month: month, year: year))
        return min(1.0, max(0.0, s / lim))
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(budgets)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch { }
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CategoryBudget].self, from: data)
        else {
            budgets = []
            return
        }
        budgets = decoded
    }
}
