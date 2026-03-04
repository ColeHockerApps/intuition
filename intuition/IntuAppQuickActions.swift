import SwiftUI
import Combine
import Foundation
import UIKit

@MainActor
final class IntuAppQuickActions: ObservableObject {

    enum Action: String, CaseIterable {
        case addExpense
        case addIncome
        case openBudget
        case openInsights
    }

    @Published private(set) var lastAction: Action? = nil

    private let handledKey = "intuapp.quickactions.handled"
    private var isInstalled: Bool = false

    init() {}

    // Call from App/Entry on launch and when app becomes active.
    func installIfNeeded() {
        guard isInstalled == false else { return }
        isInstalled = true

        UIApplication.shared.shortcutItems = [
            makeItem(.addExpense),
            makeItem(.addIncome),
            makeItem(.openBudget),
            makeItem(.openInsights)
        ]
    }

    // Call from AppDelegate: performActionFor shortcutItem
    func handle(shortcutItem: UIApplicationShortcutItem) {
        guard let a = Action(rawValue: shortcutItem.type) else { return }
        emit(a)
    }

    // Optional: if you store the type somewhere and want to replay it once
    func handlePendingIfAny(type: String?) {
        guard let type else { return }
        guard let a = Action(rawValue: type) else { return }

        let key = "\(handledKey).\(type)"
        if UserDefaults.standard.bool(forKey: key) { return }

        UserDefaults.standard.set(true, forKey: key)
        emit(a)
    }

    func clearHandledCache() {
        for a in Action.allCases {
            UserDefaults.standard.removeObject(forKey: "\(handledKey).\(a.rawValue)")
        }
    }

    // MARK: - Private

    private func emit(_ a: Action) {
        lastAction = a
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.lastAction = nil
        }
    }

    private func makeItem(_ a: Action) -> UIApplicationShortcutItem {

        let title: String
        let icon: UIApplicationShortcutIcon?

        switch a {
        case .addExpense:
            title = "Add Expense"
            icon = UIApplicationShortcutIcon(systemImageName: "minus.circle")
        case .addIncome:
            title = "Add Income"
            icon = UIApplicationShortcutIcon(systemImageName: "plus.circle")
        case .openBudget:
            title = "Budget"
            icon = UIApplicationShortcutIcon(systemImageName: "chart.pie")
        case .openInsights:
            title = "Insights"
            icon = UIApplicationShortcutIcon(systemImageName: "chart.line.uptrend.xyaxis")
        }

        return UIApplicationShortcutItem(
            type: a.rawValue,
            localizedTitle: title,
            localizedSubtitle: nil,
            icon: icon,
            userInfo: nil
        )
    }
}
