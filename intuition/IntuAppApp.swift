import SwiftUI
import Combine

@main
struct IntuAppApp: App {

    @UIApplicationDelegateAdaptor(IntuAppFlowDelegate.self) private var flow

    @StateObject private var router = IntuAppRouter()
    @StateObject private var launch = IntuAppLaunchStore()
    @StateObject private var session = IntuAppSessionState()
    @StateObject private var orientation = IntuAppOrientationManager()

    var body: some Scene {
        WindowGroup {
            IntuAppEntryScreen()
                .environmentObject(router)
                .environmentObject(launch)
                .environmentObject(session)
                .environmentObject(orientation)
        }
    }
}
