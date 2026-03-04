import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppLaunchStore: ObservableObject {

    private let resumeKey = "intuapp.resume.url"
    private let marksKey = "intuapp.cookies.marks"

    let mainPoint: URL

    init() {
        self.mainPoint = URL(string: "https://auroraricci.github.io/intuition/")!
    }

    func restoreResume() -> URL? {
        guard
            let raw = UserDefaults.standard.string(forKey: resumeKey),
            let url = URL(string: raw)
        else {
            return nil
        }
        return url
    }

    func storeResumeIfNeeded(_ value: URL) {
        let now = normalize(value)
        let base = normalize(mainPoint)

        guard now != base else { return }

        UserDefaults.standard.set(value.absoluteString, forKey: resumeKey)
    }

    func clearResume() {
        UserDefaults.standard.removeObject(forKey: resumeKey)
    }

    func saveMarks(_ list: [[String: Any]]) {
        guard JSONSerialization.isValidJSONObject(list) else { return }

        do {
            let data = try JSONSerialization.data(withJSONObject: list)
            UserDefaults.standard.set(data, forKey: marksKey)
        } catch {}
    }

    func loadMarks() -> [[String: Any]] {
        guard
            let data = UserDefaults.standard.data(forKey: marksKey),
            let obj = try? JSONSerialization.jsonObject(with: data),
            let arr = obj as? [[String: Any]]
        else {
            return []
        }

        return arr
    }

    private func normalize(_ url: URL) -> String {
        var s = url.absoluteString
        while s.count > 1, s.hasSuffix("/") {
            s.removeLast()
        }
        return s
    }
}
