import SwiftUI
import Combine
import UIKit

@MainActor
final class IntuAppOrientationManager: ObservableObject {

    enum Mode {
        case portrait
    }

    @Published private(set) var mode: Mode = .portrait
    @Published private(set) var activeValue: URL? = nil

    init() {}

    func lockPortrait() {
        mode = .portrait
        IntuAppFlowDelegate.shared?.lockPortrait()
        UIViewController.attemptRotationToDeviceOrientation()
    }

    func setActiveValue(_ value: URL?) {
        activeValue = normalizeTrailingSlash(value)
    }

    private func normalizeTrailingSlash(_ point: URL?) -> URL? {
        guard let point else { return nil }

        let scheme = point.scheme?.lowercased() ?? ""
        guard scheme == "http" || scheme == "https" else { return point }

        guard var c = URLComponents(url: point, resolvingAgainstBaseURL: false) else {
            return point
        }

        if c.path.count > 1, c.path.hasSuffix("/") {
            while c.path.count > 1, c.path.hasSuffix("/") {
                c.path.removeLast()
            }
        }

        return c.url ?? point
    }

    var interfaceMask: UIInterfaceOrientationMask {
        return [.portrait]
    }
}
