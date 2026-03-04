import UIKit
import SwiftUI

final class IntuAppFlowDelegate: NSObject, UIApplicationDelegate {

    static weak var shared: IntuAppFlowDelegate?

    private var forcedMask: UIInterfaceOrientationMask = [.portrait]

    override init() {
        super.init()
        IntuAppFlowDelegate.shared = self
    }

    func lockPortrait() {
        forcedMask = [.portrait]
        UIViewController.attemptRotationToDeviceOrientation()
    }

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        forcedMask
    }
}
