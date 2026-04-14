import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showFilePicker = false

    private var waitMinBinding: Binding<Double> {
        Binding(
            get: { viewModel.settingsManager.waitMin },
            set: { viewModel.settingsManager.waitMin = $0 }
        )
    }

    private var waitMaxBinding: Binding<Double> {
        Binding(
            get: { viewModel.settingsManager.waitMax },
            set: { viewModel.settingsManager.waitMax = $0 }
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 40)

            VStack(spacing: 24) {
                // MARK: - Song Selection
                VStack(alignment: .leading, spacing: 10) {
                    Label("Music", systemImage: "music.note")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.settingsManager.customSongName ?? "Jarabe Tapatío")
                                .font(.body.weight(.medium))
                                .foregroundColor(.white)

                            if viewModel.settingsManager.customSongName != nil {
                                Text("Custom song")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            } else {
                                Text("Built-in (default)")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        Spacer()

                        if viewModel.settingsManager.customSongName != nil {
                            Button {
                                viewModel.settingsManager.resetToDefaultSong()
                                viewModel.applySettings()
                                viewModel.audioManager.reloadSong()
                            } label: {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }

                        Button {
                            showFilePicker = true
                        } label: {
                            Text("Choose")
                                .font(.body.weight(.semibold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(16)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // MARK: - Wait Time
                VStack(alignment: .leading, spacing: 10) {
                    Label("Wait Time Between Flags", systemImage: "timer")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)

                    VStack(spacing: 12) {
                        HStack {
                            Text("Min")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 36)
                            Slider(value: waitMinBinding, in: 1...10, step: 0.5)
                                .tint(.orange)
                                .onChange(of: viewModel.settingsManager.waitMin) { newValue in
                                    if viewModel.settingsManager.waitMax < newValue + 1 {
                                        viewModel.settingsManager.waitMax = newValue + 1
                                    }
                                }
                            Text("\(viewModel.settingsManager.waitMin, specifier: "%.1f")s")
                                .font(.body.monospacedDigit())
                                .foregroundColor(.white)
                                .frame(width: 44)
                        }

                        HStack {
                            Text("Max")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 36)
                            Slider(value: waitMaxBinding, in: 2...20, step: 0.5)
                                .tint(.orange)
                                .onChange(of: viewModel.settingsManager.waitMax) { newValue in
                                    if viewModel.settingsManager.waitMin > newValue - 1 {
                                        viewModel.settingsManager.waitMin = newValue - 1
                                    }
                                }
                            Text("\(viewModel.settingsManager.waitMax, specifier: "%.1f")s")
                                .font(.body.monospacedDigit())
                                .foregroundColor(.white)
                                .frame(width: 44)
                        }
                    }

                    Text("How long music plays before each flag appears")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(16)
                .background(.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                viewModel.applySettings()
                viewModel.returnToStart()
            } label: {
                Text("Done")
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
        .sheet(isPresented: $showFilePicker) {
            AudioFilePicker { url, name in
                viewModel.settingsManager.saveCustomSong(url: url, name: name)
                viewModel.applySettings()
                viewModel.audioManager.reloadSong()
            }
        }
    }
}

// MARK: - Audio File Picker (UIDocumentPickerViewController)

struct AudioFilePicker: UIViewControllerRepresentable {
    var onPick: (URL, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL, String) -> Void

        init(onPick: @escaping (URL, String) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            let name = url.deletingPathExtension().lastPathComponent
            onPick(url, name)
            url.stopAccessingSecurityScopedResource()
        }
    }
}
