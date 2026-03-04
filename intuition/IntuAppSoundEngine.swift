import SwiftUI
import Combine
import AVFoundation

@MainActor
final class IntuAppSoundEngine: ObservableObject {

    static let shared = IntuAppSoundEngine()

    @Published var isEnabled: Bool = true

    private let enabledKey = "intuapp.sound.enabled"

    private var player: AVAudioPlayer?
    private var didWarm: Bool = false

    private init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: enabledKey) != nil {
            isEnabled = defaults.bool(forKey: enabledKey)
        } else {
            isEnabled = true
        }
    }

    func setEnabled(_ value: Bool) {
        isEnabled = value
        UserDefaults.standard.set(value, forKey: enabledKey)
        if value {
            warmIfNeeded()
        } else {
            stopAll()
        }
    }

    func warmIfNeeded() {
        guard isEnabled else { return }
        guard didWarm == false else { return }
        didWarm = true

        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [])
        } catch { }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.didWarm = false
        }
    }

    func stopAll() {
        player?.stop()
        player = nil
    }

    func tap() {
        playSystem(1104)
    }

    func soft() {
        playSystem(1105)
    }

    func success() {
        playSystem(1110)
    }

    func warning() {
        playSystem(1107)
    }

    func error() {
        playSystem(1053)
    }

    private func playSystem(_ id: SystemSoundID) {
        guard isEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }
}
