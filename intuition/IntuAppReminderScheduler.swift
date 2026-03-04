import SwiftUI
import Combine
import UserNotifications

@MainActor
final class IntuAppReminderScheduler: ObservableObject {

    static let shared = IntuAppReminderScheduler()

    struct ReminderRule: Codable, Equatable, Identifiable {
        let id: String
        var isEnabled: Bool
        var hour: Int
        var minute: Int
        var title: String
        var body: String
    }

    @Published private(set) var authorization: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastError: String? = nil
    @Published private(set) var rules: [ReminderRule] = []

    private let center = UNUserNotificationCenter.current()
    private let rulesKey = "intuapp.reminders.rules.v1"
    private var didLoad = false

    private init() {}

    func loadIfNeeded() {
        guard didLoad == false else { return }
        didLoad = true

        rules = loadRulesFromDefaults() ?? defaultRules()
        refreshAuthStatus()
    }

    func refreshAuthStatus() {
        center.getNotificationSettings { [weak self] s in
            DispatchQueue.main.async {
                self?.authorization = s.authorizationStatus
            }
        }
    }

    func requestPermissionIfNeeded() {
        lastError = nil
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, err in
            DispatchQueue.main.async {
                if let err { self?.lastError = err.localizedDescription }
                self?.refreshAuthStatus()
                if granted {
                    self?.applyAll()
                }
            }
        }
    }

    func setRuleEnabled(id: String, enabled: Bool) {
        guard let ix = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[ix].isEnabled = enabled
        persistRules()
    }

    func updateTime(id: String, hour: Int, minute: Int) {
        guard let ix = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[ix].hour = clamp(hour, 0, 23)
        rules[ix].minute = clamp(minute, 0, 59)
        persistRules()
    }

    func updateText(id: String, title: String, body: String) {
        guard let ix = rules.firstIndex(where: { $0.id == id }) else { return }
        rules[ix].title = safeText(title, max: 60)
        rules[ix].body = safeText(body, max: 140)
        persistRules()
    }

    func applyAll() {
        lastError = nil
        refreshAuthStatus()

        center.getNotificationSettings { [weak self] s in
            guard let self else { return }

            if s.authorizationStatus != .authorized && s.authorizationStatus != .provisional {
                DispatchQueue.main.async {
                    self.lastError = "Notifications are not authorized."
                    self.authorization = s.authorizationStatus
                }
                return
            }

            let enabledIds = Set(self.rules.filter { $0.isEnabled }.map { self.makeNotificationId($0.id) })

            self.center.getPendingNotificationRequests { [weak self] requests in
                guard let self else { return }

                let ours = requests.filter { $0.identifier.hasPrefix("intuapp.reminder.") }
                let toRemove = ours
                    .map { $0.identifier }
                    .filter { !enabledIds.contains($0) }

                if !toRemove.isEmpty {
                    self.center.removePendingNotificationRequests(withIdentifiers: toRemove)
                }

                let existing = Set(ours.map { $0.identifier })

                for r in self.rules where r.isEnabled {
                    let nid = self.makeNotificationId(r.id)
                    if existing.contains(nid) {
                        self.center.removePendingNotificationRequests(withIdentifiers: [nid])
                    }
                    self.schedule(rule: r)
                }
            }
        }
    }

    func cancelAll() {
        lastError = nil
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            let ids = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("intuapp.reminder.") }
            self.center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Scheduling

    private func schedule(rule: ReminderRule) {
        let content = UNMutableNotificationContent()
        content.title = rule.title.isEmpty ? "Reminder" : rule.title
        content.body = rule.body
        content.sound = .default

        var dc = DateComponents()
        dc.hour = clamp(rule.hour, 0, 23)
        dc.minute = clamp(rule.minute, 0, 59)

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: makeNotificationId(rule.id), content: content, trigger: trigger)

        center.add(req) { [weak self] err in
            DispatchQueue.main.async {
                if let err { self?.lastError = err.localizedDescription }
            }
        }
    }

    private func makeNotificationId(_ id: String) -> String {
        "intuapp.reminder.\(id)"
    }

    // MARK: - Persistence

    private func persistRules() {
        do {
            let data = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(data, forKey: rulesKey)
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func loadRulesFromDefaults() -> [ReminderRule]? {
        guard let data = UserDefaults.standard.data(forKey: rulesKey) else { return nil }
        return try? JSONDecoder().decode([ReminderRule].self, from: data)
    }

    // MARK: - Defaults

    private func defaultRules() -> [ReminderRule] {
        [
            ReminderRule(
                id: "log_today",
                isEnabled: false,
                hour: 20,
                minute: 30,
                title: "Quick check-in",
                body: "Log today’s expenses in 30 seconds."
            ),
            ReminderRule(
                id: "plan_week",
                isEnabled: false,
                hour: 10,
                minute: 0,
                title: "Weekly plan",
                body: "Set a budget focus for the week."
            )
        ]
    }

    // MARK: - Utils

    private func clamp(_ v: Int, _ a: Int, _ b: Int) -> Int {
        if v < a { return a }
        if v > b { return b }
        return v
    }

    private func safeText(_ s: String, max: Int) -> String {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count <= max { return t }
        return String(t.prefix(max))
    }
}
