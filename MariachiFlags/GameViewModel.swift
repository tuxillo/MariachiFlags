import SwiftUI
import Combine

enum GamePhase {
    case start
    case highScores
    case listening
    case guessing
    case result
    case finished
}

class GameViewModel: ObservableObject {
    @Published var phase: GamePhase = .start
    @Published var currentCountry: Country?
    @Published var options: [Country] = []
    @Published var score = 0
    @Published var lives = 3
    @Published var streak = 0
    @Published var bestStreak = 0
    @Published var lastAnswerCorrect: Bool?
    @Published var selectedAnswer: String?
    @Published var isNewHighScore = false
    @Published var timeRemaining: Double = 0
    @Published var timedOut = false

    let maxLives = 3
    let audioManager = AudioManager()
    let highScoreManager = HighScoreManager()

    private var usedCountries: Set<String> = []
    private var guessTimer: Timer?
    private var guessDeadline: Date?
    private var isPaused = false

    /// Starts at 10s, decreases by 0.5s per correct answer, minimum 4s
    var currentTimeLimit: Double {
        max(4.0, 10.0 - Double(score) * 0.5)
    }

    func startGame() {
        score = 0
        lives = maxLives
        streak = 0
        bestStreak = 0
        usedCountries = []
        lastAnswerCorrect = nil
        selectedAnswer = nil
        isNewHighScore = false
        timedOut = false
        startListening()
    }

    func showHighScores() {
        withAnimation { phase = .highScores }
    }

    func startListening() {
        phase = .listening
        audioManager.startMusic { [weak self] in
            DispatchQueue.main.async {
                self?.presentFlag()
            }
        }
    }

    private func presentFlag() {
        if usedCountries.count >= allCountries.count - 4 {
            usedCountries.removeAll()
        }

        let available = allCountries.filter { !usedCountries.contains($0.name) }
        guard let correct = available.randomElement() else { return }

        usedCountries.insert(correct.name)
        currentCountry = correct

        var opts: [Country] = [correct]
        let others = allCountries.filter { $0.name != correct.name }.shuffled()
        for country in others where opts.count < 4 {
            opts.append(country)
        }
        options = opts.shuffled()

        lastAnswerCorrect = nil
        selectedAnswer = nil
        timedOut = false

        let limit = currentTimeLimit
        timeRemaining = limit
        guessDeadline = Date().addingTimeInterval(limit)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            phase = .guessing
        }

        startGuessTimer()
    }

    private func startGuessTimer() {
        guessTimer?.invalidate()
        guessTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self, let deadline = self.guessDeadline else { return }
            let remaining = deadline.timeIntervalSinceNow
            if remaining <= 0 {
                self.guessTimer?.invalidate()
                self.guessTimer = nil
                self.timeRemaining = 0
                self.handleTimeout()
            } else {
                self.timeRemaining = remaining
            }
        }
    }

    private func handleTimeout() {
        guard phase == .guessing else { return }
        timedOut = true
        lives -= 1
        streak = 0
        lastAnswerCorrect = false

        withAnimation {
            phase = .result
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            if self.lives <= 0 {
                self.endGame()
            } else {
                self.continueAfterResult()
            }
        }
    }

    func submitAnswer(_ countryName: String) {
        guard let correct = currentCountry, phase == .guessing else { return }

        guessTimer?.invalidate()
        guessTimer = nil

        selectedAnswer = countryName
        let isCorrect = countryName == correct.name

        if isCorrect {
            score += 1
            streak += 1
            if streak > bestStreak { bestStreak = streak }
        } else {
            lives -= 1
            streak = 0
        }

        lastAnswerCorrect = isCorrect

        withAnimation {
            phase = .result
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self else { return }
            if self.lives <= 0 {
                self.endGame()
            } else {
                self.continueAfterResult()
            }
        }
    }

    private func continueAfterResult() {
        audioManager.raiseVolume()
        phase = .listening
    }

    private func endGame() {
        audioManager.stopMusic()
        isNewHighScore = highScoreManager.isHighScore(score)
        highScoreManager.addScore(score, streak: bestStreak)
        withAnimation {
            phase = .finished
        }
    }

    func quitGame() {
        guessTimer?.invalidate()
        guessTimer = nil
        audioManager.stopMusic()
        if score > 0 {
            isNewHighScore = highScoreManager.isHighScore(score)
            highScoreManager.addScore(score, streak: bestStreak)
        }
        withAnimation {
            phase = .start
        }
    }

    func returnToStart() {
        phase = .start
    }

    func handleBackground() {
        isPaused = true
        guessTimer?.invalidate()
        guessTimer = nil
        audioManager.pause()
    }

    func handleForeground() {
        isPaused = false
        switch phase {
        case .listening:
            audioManager.resumeLoud()
        case .guessing:
            audioManager.resumeQuiet()
            // Resume the countdown
            startGuessTimer()
        case .result:
            audioManager.resumeQuiet()
        case .start, .highScores, .finished:
            break
        }
    }
}
