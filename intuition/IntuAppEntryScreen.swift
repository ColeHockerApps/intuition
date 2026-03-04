import SwiftUI
import Combine

struct IntuAppEntryScreen: View {

    @EnvironmentObject private var router: IntuAppRouter
    @EnvironmentObject private var launch: IntuAppLaunchStore
    @EnvironmentObject private var session: IntuAppSessionState
    @EnvironmentObject private var orientation: IntuAppOrientationManager

    @StateObject private var loading = IntuAppLoadingModel()

    @State private var showPlay: Bool = false

    var body: some View {
        ZStack {
            IntuAppTheme.background
                .ignoresSafeArea()

            if showPlay {
                IntuAppPlayContainer {
                    loading.completeNow()
                }
            } else {
                IntuAppLoadingScreen()
            }
        }
        .onAppear {
            orientation.lockPortrait()

            loading.start(minSeconds: 1.2)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                showPlay = true
            }
        }
    }
}
