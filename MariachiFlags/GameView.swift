import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: backgroundColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.5), value: viewModel.phase)

            switch viewModel.phase {
            case .start:
                StartView(viewModel: viewModel)
            case .highScores:
                HighScoresView(viewModel: viewModel)
            case .listening:
                ListeningView(viewModel: viewModel)
            case .guessing:
                GuessingView(viewModel: viewModel)
            case .result:
                ResultView(viewModel: viewModel)
            case .finished:
                FinishedView(viewModel: viewModel)
            }
        }
    }

    private var backgroundColors: [Color] {
        switch viewModel.phase {
        case .start, .highScores: return [.orange, .yellow]
        case .listening:          return [.purple, .blue]
        case .guessing:           return [.teal, .cyan]
        case .result:
            if viewModel.lastAnswerCorrect == true {
                return [.green, .mint]
            } else {
                return [.red, .orange]
            }
        case .finished:           return [.indigo, .purple]
        }
    }
}

// MARK: - Game Top Bar

struct GameTopBar: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        HStack {
            Button {
                viewModel.quitGame()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.7))
            }

            HStack(spacing: 4) {
                ForEach(0..<viewModel.maxLives, id: \.self) { i in
                    Image(systemName: i < viewModel.lives ? "heart.fill" : "heart")
                        .foregroundColor(.red)
                        .font(.title3)
                }
            }

            Spacer()

            Label("\(viewModel.score)", systemImage: "star.fill")
                .font(.title2.weight(.bold))
                .foregroundColor(.yellow)
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

// MARK: - Timer Bar

struct TimerBar: View {
    let timeRemaining: Double
    let timeLimit: Double

    private var fraction: Double {
        guard timeLimit > 0 else { return 0 }
        return max(0, min(1, timeRemaining / timeLimit))
    }

    private var barColor: Color {
        if fraction > 0.5 { return .green }
        if fraction > 0.25 { return .yellow }
        return .red
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(.white.opacity(0.3))

                RoundedRectangle(cornerRadius: 6)
                    .fill(barColor)
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Start Screen

struct StartView: View {
    @ObservedObject var viewModel: GameViewModel

    @State private var bouncing = false

    var body: some View {
        VStack(spacing: 30) {
            Text("🎵🇲🇽")
                .font(.system(size: 80))
                .offset(y: bouncing ? -20 : 0)
                .animation(
                    .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                    value: bouncing
                )

            Text("Mariachi Flags!")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(radius: 4)

            Text("Listen to the music...\nWhen it gets quiet, guess the flag!")
                .font(.title3)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                viewModel.startGame()
            } label: {
                Text("Play!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 8)
            }
            .padding(.top, 20)

            Button {
                viewModel.showHighScores()
            } label: {
                Label("High Scores", systemImage: "trophy.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.white)
            }
        }
        .onAppear { bouncing = true }
    }
}

// MARK: - High Scores

struct HighScoresView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("🏆")
                .font(.system(size: 60))

            Text("High Scores")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            if viewModel.highScoreManager.entries.isEmpty {
                Text("No scores yet!\nPlay a game first!")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(viewModel.highScoreManager.entries.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            Text(medal(for: index))
                                .font(.title2)
                                .frame(width: 36)

                            Text("\(entry.score)")
                                .font(.title2.weight(.bold).monospacedDigit())
                                .foregroundColor(.white)

                            Spacer()

                            if entry.streak > 1 {
                                Text("🔥\(entry.streak)")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.yellow)
                            }

                            Text(entry.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                viewModel.returnToStart()
            } label: {
                Text("Back")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
            }
            .padding(.bottom, 40)
        }
        .padding(.top, 40)
    }

    private func medal(for index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "\(index + 1)."
        }
    }
}

// MARK: - Listening (Music Playing)

struct ListeningView: View {
    @ObservedObject var viewModel: GameViewModel

    @State private var noteOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        VStack(spacing: 40) {
            GameTopBar(viewModel: viewModel)

            Spacer()

            Text("🎶")
                .font(.system(size: 100))
                .rotationEffect(.degrees(rotation))
                .offset(y: noteOffset)
                .animation(
                    .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                    value: noteOffset
                )
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: rotation
                )

            Text("Listen...")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if viewModel.streak > 1 {
                Text("🔥 \(viewModel.streak) in a row!")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.yellow)
            }

            Spacer()
        }
        .padding()
        .onAppear {
            noteOffset = -30
            rotation = 15
        }
    }
}

// MARK: - Guessing (Flag Shown)

struct GuessingView: View {
    @ObservedObject var viewModel: GameViewModel

    @State private var flagScale: CGFloat = 0.1

    var body: some View {
        VStack(spacing: 24) {
            GameTopBar(viewModel: viewModel)

            TimerBar(timeRemaining: viewModel.timeRemaining, timeLimit: viewModel.currentTimeLimit)
                .padding(.horizontal)

            Spacer()

            if let country = viewModel.currentCountry {
                Text(country.flag)
                    .font(.system(size: 140))
                    .scaleEffect(flagScale)
                    .onAppear {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                            flagScale = 1.0
                        }
                    }
            }

            Text("Which country is this?")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                ForEach(viewModel.options) { option in
                    Button {
                        viewModel.submitAnswer(option.name)
                    } label: {
                        Text(option.name)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.teal)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(radius: 4)
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Result

struct ResultView: View {
    @ObservedObject var viewModel: GameViewModel

    var body: some View {
        VStack(spacing: 24) {
            GameTopBar(viewModel: viewModel)

            Spacer()

            if let country = viewModel.currentCountry {
                Text(country.flag)
                    .font(.system(size: 100))

                Text(country.name)
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)
            }

            if viewModel.lastAnswerCorrect == true {
                Text("Correct!")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("⭐️")
                    .font(.system(size: 60))
            } else if viewModel.timedOut {
                Text("Time's up!")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text("⏰")
                    .font(.system(size: 60))
            } else {
                Text("Not quite!")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                if let selected = viewModel.selectedAnswer {
                    Text("You picked: \(selected)")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                Text("❤️‍🩹")
                    .font(.system(size: 60))
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Finished

struct FinishedView: View {
    @ObservedObject var viewModel: GameViewModel

    @State private var starScale: CGFloat = 0.1

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(viewModel.isNewHighScore ? "🎉🏆🎉" : "🎉")
                .font(.system(size: 80))
                .scaleEffect(starScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
                        starScale = 1.0
                    }
                }

            if viewModel.isNewHighScore {
                Text("New High Score!")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
            }

            Text("Game Over!")
                .font(.system(size: 42, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            Text("Score: \(viewModel.score)")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            if viewModel.bestStreak > 1 {
                Text("Best streak: \(viewModel.bestStreak) 🔥")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.yellow)
            }

            HStack(spacing: 16) {
                Button {
                    viewModel.returnToStart()
                } label: {
                    Text("Play Again!")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.indigo)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 8)
                }

                Button {
                    viewModel.showHighScores()
                } label: {
                    Image(systemName: "trophy.fill")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.indigo)
                        .padding(14)
                        .background(.white)
                        .clipShape(Circle())
                        .shadow(radius: 8)
                }
            }
            .padding(.top, 20)

            Spacer()
        }
    }
}

#Preview {
    GameView(viewModel: GameViewModel())
}
