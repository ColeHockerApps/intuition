import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppInsightsEngine: ObservableObject {

    struct Insight: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let value: String
        let description: String
        let trend: Trend
    }

    enum Trend: String {
        case up
        case down
        case neutral
    }

    struct CategoryInsight: Identifiable, Hashable {
        let id = UUID()
        let category: String
        let amount: Double
        let percentage: Double
    }

    @Published private(set) var insights: [Insight] = []
    @Published private(set) var categoryBreakdown: [CategoryInsight] = []

    init() {}

    // MARK: - Main analysis

    func analyze(ledger: IntuAppLedgerStore) {

        let entries = ledger.entries
        guard entries.isEmpty == false else {
            insights = []
            categoryBreakdown = []
            return
        }

        let income = entries
            .filter { $0.amount > 0 }
            .reduce(0.0) { $0 + $1.amount }

        let expenses = entries
            .filter { $0.amount < 0 }
            .reduce(0.0) { $0 + abs($1.amount) }

        let balance = income - expenses

        let avgExpense = expenses / Double(max(1, entries.filter { $0.amount < 0 }.count))

        insights = [
            Insight(
                title: "Total Income",
                value: format(income),
                description: "All recorded income",
                trend: .up
            ),
            Insight(
                title: "Total Expenses",
                value: format(expenses),
                description: "Money spent",
                trend: .down
            ),
            Insight(
                title: "Balance",
                value: format(balance),
                description: "Income minus expenses",
                trend: balance >= 0 ? .up : .down
            ),
            Insight(
                title: "Avg Expense",
                value: format(avgExpense),
                description: "Average spending per entry",
                trend: .neutral
            )
        ]

        buildCategoryBreakdown(entries: entries)
    }

    // MARK: - Category breakdown

    private func buildCategoryBreakdown(entries: [IntuAppLedgerStore.Entry]) {

        let expenses = entries.filter { $0.amount < 0 }

        let total = expenses.reduce(0.0) { $0 + abs($1.amount) }

        guard total > 0 else {
            categoryBreakdown = []
            return
        }

        let grouped = Dictionary(grouping: expenses, by: { $0.category })

        let result = grouped.map { category, items -> CategoryInsight in
            let sum = items.reduce(0.0) { $0 + abs($1.amount) }
            return CategoryInsight(
                category: category,
                amount: sum,
                percentage: sum / total
            )
        }

        categoryBreakdown = result.sorted { $0.amount > $1.amount }
    }

    // MARK: - Helpers

    private func format(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
