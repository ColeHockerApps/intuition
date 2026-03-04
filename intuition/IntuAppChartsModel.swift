import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppChartsModel: ObservableObject {

    struct Point: Identifiable, Equatable {
        let id: UUID = UUID()
        let t: TimeInterval
        let value: Double
        let label: String
    }

    struct Series: Identifiable, Equatable {
        let id: UUID = UUID()
        let title: String
        let points: [Point]
        let total: Double
        let min: Double
        let max: Double
    }

    enum RangeKind: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case quarter = "90D"
        case year = "1Y"
    }

    @Published private(set) var range: RangeKind = .month
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var income: Series = Series(title: "Income", points: [], total: 0, min: 0, max: 0)
    @Published private(set) var expense: Series = Series(title: "Expense", points: [], total: 0, min: 0, max: 0)
    @Published private(set) var balance: Series = Series(title: "Balance", points: [], total: 0, min: 0, max: 0)

    private var cancellables = Set<AnyCancellable>()

    init() {}

    func setRange(_ next: RangeKind) {
        range = next
    }

    func reload(using ledger: IntuAppLedgerStore) {
        isLoading = true

       // let snapshot = ledger.snapshot()
        let now = Date()
        let start = rangeStart(for: range, now: now)

//        let filtered = snapshot
//            .filter { $0.date >= start && $0.date <= now }
//            .sorted { $0.date < $1.date }

      //  let buckets = bucketedTotals(items: filtered, range: range)
//
//        let incomePoints = buckets.map { b in
//            Point(t: b.t, value: b.income, label: b.label)
//        }
//        let expensePoints = buckets.map { b in
//            Point(t: b.t, value: b.expense, label: b.label)
//        }
//        let balancePoints = buckets.map { b in
//            Point(t: b.t, value: (b.income - b.expense), label: b.label)
//        }
//
//        income = buildSeries(title: "Income", points: incomePoints)
//        expense = buildSeries(title: "Expense", points: expensePoints)
//        balance = buildSeries(title: "Balance", points: balancePoints)

        isLoading = false
    }

    // MARK: - Helpers

    private func buildSeries(title: String, points: [Point]) -> Series {
        let total = points.reduce(0.0) { $0 + $1.value }
        let minV = points.map { $0.value }.min() ?? 0
        let maxV = points.map { $0.value }.max() ?? 0
        return Series(title: title, points: points, total: total, min: minV, max: maxV)
    }

    private func rangeStart(for range: RangeKind, now: Date) -> Date {
        let cal = Calendar.current
        switch range {
        case .week:
            return cal.date(byAdding: .day, value: -6, to: now) ?? now
        case .month:
            return cal.date(byAdding: .day, value: -29, to: now) ?? now
        case .quarter:
            return cal.date(byAdding: .day, value: -89, to: now) ?? now
        case .year:
            return cal.date(byAdding: .day, value: -364, to: now) ?? now
        }
    }

    private struct Bucket {
        let t: TimeInterval
        let label: String
        var income: Double
        var expense: Double
    }

    private func bucketedTotals(items: [IntuAppLedgerStore.Entry], range: RangeKind) -> [Bucket] {
        let cal = Calendar.current
        let df = DateFormatter()
        df.locale = Locale.current

        let byDay: Bool
        let stepDays: Int

        switch range {
        case .week:
            byDay = true
            stepDays = 1
            df.setLocalizedDateFormatFromTemplate("EEE")
        case .month:
            byDay = true
            stepDays = 1
            df.setLocalizedDateFormatFromTemplate("d MMM")
        case .quarter:
            byDay = true
            stepDays = 7
            df.setLocalizedDateFormatFromTemplate("d MMM")
        case .year:
            byDay = false
            stepDays = 30
            df.setLocalizedDateFormatFromTemplate("MMM")
        }

        guard let first = items.first?.date else { return [] }
        let start = cal.startOfDay(for: first)
        let end = cal.startOfDay(for: items.last?.date ?? first)

        var cursor = start
        var buckets: [Bucket] = []

        while cursor <= end {
            let label = df.string(from: cursor)
            buckets.append(Bucket(t: cursor.timeIntervalSince1970, label: label, income: 0, expense: 0))

            if byDay {
                cursor = cal.date(byAdding: .day, value: stepDays, to: cursor) ?? end.addingTimeInterval(86400)
            } else {
                cursor = cal.date(byAdding: .day, value: stepDays, to: cursor) ?? end.addingTimeInterval(86400 * Double(stepDays))
            }
        }

        if buckets.isEmpty { return [] }

        func bucketIndex(for date: Date) -> Int {
            let d0 = cal.startOfDay(for: date)
            let dt = d0.timeIntervalSince(start)
            let step = Double(stepDays) * 86400.0
            let i = Int(floor(dt / max(1, step)))
            return max(0, min(buckets.count - 1, i))
        }

        var out = buckets
        for it in items {
            let i = bucketIndex(for: it.date)
            if it.amount >= 0 {
                out[i].income += it.amount
            } else {
                out[i].expense += abs(it.amount)
            }
        }

        return out
    }
}
