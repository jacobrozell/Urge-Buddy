import AVFoundation

/// The short tone that plays once when an urge countdown reaches zero.
/// Ambient, so the silent switch and anything already playing both win.
enum UrgeTimerChime {
    private static let player: AVAudioPlayer? = {
        guard !ProcessInfo.processInfo.arguments.contains("-ui_testing") else { return nil }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true)
        guard let url = Bundle.main.url(forResource: "urge-timer-done", withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        return player
    }()

    static func play() {
        guard let player else { return }
        player.currentTime = 0
        player.play()
    }
}
