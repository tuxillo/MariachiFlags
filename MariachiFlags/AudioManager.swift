import AVFoundation
import Combine

class AudioManager: ObservableObject {
    @Published var isPlaying = false

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var onFlagTime: (() -> Void)?

    private let normalVolume: Float = 0.3
    private let quietVolume: Float = 0.08

    /// External config — set by GameViewModel from SettingsManager
    var waitMin: Double = 3.0
    var waitMax: Double = 8.0
    var customSongURL: URL?

    func startMusic(onFlagTime: @escaping () -> Void) {
        self.onFlagTime = onFlagTime

        if audioPlayer == nil {
            loadAudioPlayer()
        }

        audioPlayer?.volume = normalVolume
        audioPlayer?.play()
        isPlaying = true
        scheduleNextFlag()
    }

    func lowerVolume() {
        fadeVolume(to: quietVolume, duration: 0.5)
    }

    func raiseVolume() {
        fadeVolume(to: normalVolume, duration: 0.5)
        scheduleNextFlag()
    }

    func stopMusic() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    func pause() {
        timer?.invalidate()
        timer = nil
        audioPlayer?.pause()
        isPlaying = false
    }

    func resumeQuiet() {
        audioPlayer?.volume = quietVolume
        audioPlayer?.play()
        isPlaying = true
    }

    func resumeLoud() {
        audioPlayer?.volume = normalVolume
        audioPlayer?.play()
        isPlaying = true
        scheduleNextFlag()
    }

    /// Reload audio player (call when song changes in settings)
    func reloadSong() {
        let wasPlaying = isPlaying
        audioPlayer?.stop()
        audioPlayer = nil
        loadAudioPlayer()
        if wasPlaying {
            audioPlayer?.volume = normalVolume
            audioPlayer?.play()
        }
    }

    private func loadAudioPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            if let customURL = customSongURL {
                let accessing = customURL.startAccessingSecurityScopedResource()
                audioPlayer = try AVAudioPlayer(contentsOf: customURL)
                if accessing { customURL.stopAccessingSecurityScopedResource() }
            } else if let bundleURL = Bundle.main.url(forResource: "background_music", withExtension: "mp3") ??
                                       Bundle.main.url(forResource: "background_music", withExtension: "m4a") {
                audioPlayer = try AVAudioPlayer(contentsOf: bundleURL)
            }

            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = normalVolume
        } catch {
            print("Audio player error: \(error)")
        }
    }

    private func scheduleNextFlag() {
        timer?.invalidate()
        let delay = Double.random(in: waitMin...waitMax)
        timer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.lowerVolume()
            self?.onFlagTime?()
        }
    }

    private func fadeVolume(to target: Float, duration: TimeInterval) {
        guard let player = audioPlayer else { return }
        let steps = 20
        let interval = duration / Double(steps)
        let delta = (target - player.volume) / Float(steps)

        var step = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            step += 1
            player.volume += delta
            if step >= steps {
                timer.invalidate()
                player.volume = target
            }
        }
    }
}
