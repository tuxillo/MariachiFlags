import AVFoundation
import Combine

struct AudioTrack {
    let name: String
    let url: URL?   // nil = built-in bundle resource
}

class AudioManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var nowPlayingTitle: String = TrackEntry.builtIn.name
    @Published var currentTrackIndex: Int = 0

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var onFlagTime: (() -> Void)?

    private let normalVolume: Float = 0.3
    private let quietVolume: Float  = 0.08
    private var currentVolumeTarget: Float = 0.3

    var tracks: [AudioTrack] = [AudioTrack(name: TrackEntry.builtIn.name, url: nil)]
    var waitMin: Double = 3.0
    var waitMax: Double = 8.0

    // MARK: - Lifecycle

    func startMusic(onFlagTime: @escaping () -> Void) {
        self.onFlagTime = onFlagTime
        if audioPlayer == nil { loadPlayer(at: currentTrackIndex) }
        currentVolumeTarget = normalVolume
        audioPlayer?.volume = normalVolume
        audioPlayer?.play()
        isPlaying = true
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
        currentVolumeTarget = quietVolume
        audioPlayer?.volume = quietVolume
        audioPlayer?.play()
        isPlaying = true
    }

    func resumeLoud() {
        currentVolumeTarget = normalVolume
        audioPlayer?.volume = normalVolume
        audioPlayer?.play()
        isPlaying = true
        scheduleNextFlag()
    }

    func lowerVolume() {
        currentVolumeTarget = quietVolume
        fadeVolume(to: quietVolume, duration: 0.5)
    }

    func raiseVolume() {
        currentVolumeTarget = normalVolume
        fadeVolume(to: normalVolume, duration: 0.5)
        scheduleNextFlag()
    }

    // MARK: - Playlist navigation

    func playNext() {
        guard tracks.count > 1 else { return }
        switchTrack(to: (currentTrackIndex + 1) % tracks.count)
    }

    func playPrev() {
        guard tracks.count > 1 else { return }
        switchTrack(to: (currentTrackIndex - 1 + tracks.count) % tracks.count)
    }

    // MARK: - AVAudioPlayerDelegate

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard isPlaying, tracks.count > 1 else {
            // Single track or paused — restart from beginning
            player.currentTime = 0
            player.play()
            return
        }
        // Advance to next track automatically
        switchTrack(to: (currentTrackIndex + 1) % tracks.count)
        audioPlayer?.play()
        isPlaying = true
    }

    private func switchTrack(to index: Int) {
        guard index < tracks.count else { return }
        currentTrackIndex = index
        nowPlayingTitle = tracks[index].name

        let wasPlaying = isPlaying
        let vol = currentVolumeTarget

        audioPlayer?.stop()
        audioPlayer = nil
        loadPlayer(at: index)

        if wasPlaying {
            audioPlayer?.volume = vol
            audioPlayer?.play()
            isPlaying = true
        }
    }

    // Reload current track (called from settings changes)
    func reloadSong() {
        switchTrack(to: min(currentTrackIndex, max(0, tracks.count - 1)))
    }

    // MARK: - Private helpers

    private func loadPlayer(at index: Int) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { print("AVAudioSession error: \(error)") }

        let track = index < tracks.count ? tracks[index] : tracks[0]

        do {
            if let customURL = track.url {
                let accessing = customURL.startAccessingSecurityScopedResource()
                audioPlayer = try AVAudioPlayer(contentsOf: customURL)
                if accessing { customURL.stopAccessingSecurityScopedResource() }
            } else if let url = Bundle.main.url(forResource: "background_music", withExtension: "mp3") ??
                                 Bundle.main.url(forResource: "background_music", withExtension: "m4a") {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
            }
            audioPlayer?.numberOfLoops = 0   // play once, then delegate fires
            audioPlayer?.delegate = self
            audioPlayer?.volume = currentVolumeTarget
            nowPlayingTitle = track.name
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
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { t in
            step += 1
            player.volume += delta
            if step >= steps { t.invalidate(); player.volume = target }
        }
    }
}
