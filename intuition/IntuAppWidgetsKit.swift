import SwiftUI
import Combine
import WidgetKit

@MainActor
final class IntuAppWidgetsKit: ObservableObject {

    static let shared = IntuAppWidgetsKit()

    @Published private(set) var lastReload: Date? = nil

    private let groupID = "group.com.auroraricciapps.intuition"
    private let balanceKey = "intuapp.widget.balance"
    private let incomeKey = "intuapp.widget.income"
    private let expenseKey = "intuapp.widget.expense"
    private let updatedKey = "intuapp.widget.updated"

    private init() {}

    // MARK: - Public API

    func updateFromLedger(_ ledger: IntuAppLedgerStore) {

        let entries = ledger.entries

        var income: Double = 0
        var expense: Double = 0

        for e in entries {
            if e.amount >= 0 {
                income += e.amount
            } else {
                expense += abs(e.amount)
            }
        }

        let balance = income - expense

        save(balance: balance, income: income, expense: expense)
    }

    func save(balance: Double, income: Double, expense: Double) {

        guard let defaults = UserDefaults(suiteName: groupID) else { return }

        defaults.set(balance, forKey: balanceKey)
        defaults.set(income, forKey: incomeKey)
        defaults.set(expense, forKey: expenseKey)
        defaults.set(Date().timeIntervalSince1970, forKey: updatedKey)

        reloadWidgets()
    }

    func readSnapshot() -> Snapshot {

        guard let defaults = UserDefaults(suiteName: groupID) else {
            return Snapshot(balance: 0, income: 0, expense: 0, updated: nil)
        }

        let balance = defaults.double(forKey: balanceKey)
        let income = defaults.double(forKey: incomeKey)
        let expense = defaults.double(forKey: expenseKey)

        let time = defaults.double(forKey: updatedKey)
        let updated = time > 0 ? Date(timeIntervalSince1970: time) : nil

        return Snapshot(
            balance: balance,
            income: income,
            expense: expense,
            updated: updated
        )
    }

    func reloadWidgets() {
        lastReload = Date()
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Snapshot Model

    struct Snapshot: Equatable {
        let balance: Double
        let income: Double
        let expense: Double
        let updated: Date?
    }

    // MARK: - Debug helpers

    func clearWidgetData() {

        guard let defaults = UserDefaults(suiteName: groupID) else { return }

        defaults.removeObject(forKey: balanceKey)
        defaults.removeObject(forKey: incomeKey)
        defaults.removeObject(forKey: expenseKey)
        defaults.removeObject(forKey: updatedKey)

        reloadWidgets()
    }

    func seedDemoData() {

        let income = Double.random(in: 2000...5000)
        let expense = Double.random(in: 800...3000)
        let balance = income - expense

        save(balance: balance, income: income, expense: expense)
    }
}
