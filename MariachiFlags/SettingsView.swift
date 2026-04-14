import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showFilePicker = false

    private var sm: SettingsManager { viewModel.settingsManager }

    private var waitMinBinding: Binding<Double> {
        Binding(get: { sm.waitMin }, set: { sm.waitMin = $0 })
    }
    private var waitMaxBinding: Binding<Double> {
        Binding(get: { sm.waitMax }, set: { sm.waitMax = $0 })
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.system(size: 36, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .padding(.top, 40)
                .padding(.bottom, 20)

            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Tracklist
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label("Playlist", systemImage: "music.note.list")
                                .font(.title3.weight(.semibold))
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                showFilePicker = true
                            } label: {
                                Label("Add", systemImage: "plus")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.orange)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(.white)
                                    .clipShape(Capsule())
                            }
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(sm.tracks.enumerated()), id: \.element.id) { index, track in
                                HStack(spacing: 12) {
                                    // Playing indicator
                                    Image(systemName: index == viewModel.audioManager.currentTrackIndex
                                          ? "speaker.wave.2.fill" : "music.note")
                                        .font(.body)
                                        .foregroundColor(index == viewModel.audioManager.currentTrackIndex
                                                         ? .orange : .white.opacity(0.5))
                                        .frame(width: 24)

                                    Text(track.name)
                                        .font(.body.weight(index == viewModel.audioManager.currentTrackIndex ? .semibold : .regular))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    if track.isBuiltIn {
                                        Text("built-in")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.4))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(.white.opacity(0.1))
                                            .clipShape(Capsule())
                                    }

                                    Spacer()

                                    if !track.isBuiltIn {
                                        Button {
                                            sm.removeTrack(id: track.id)
                                            viewModel.applySettings()
                                            viewModel.audioManager.reloadSong()
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red.opacity(0.7))
                                        }
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(index == viewModel.audioManager.currentTrackIndex
                                            ? Color.orange.opacity(0.15) : Color.clear)

                                if index < sm.tracks.count - 1 {
                                    Divider().background(.white.opacity(0.1))
                                }
                            }
                        }
                        .background(.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        Text("Swipe left to delete · tap Add to import from Files")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 24)

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
                                Slider(value: waitMinBinding, in: 1...15, step: 0.5)
                                    .tint(.orange)
                                    .onChange(of: sm.waitMin) { v in
                                        if sm.waitMax < v + 1 { sm.waitMax = v + 1 }
                                    }
                                Text("\(sm.waitMin, specifier: "%.1f")s")
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
                                    .onChange(of: sm.waitMax) { v in
                                        if sm.waitMin > v - 1 { sm.waitMin = v - 1 }
                                    }
                                Text("\(sm.waitMax, specifier: "%.1f")s")
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
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 20)
            }

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
            .padding(.vertical, 20)
        }
        .sheet(isPresented: $showFilePicker) {
            AudioFilePicker { url, name in
                sm.addTrack(url: url, name: name)
                viewModel.applySettings()
            }
        }
    }
}

// MARK: - Audio File Picker

struct AudioFilePicker: UIViewControllerRepresentable {
    var onPick: (URL, String) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.audio, .mp3, .mpeg4Audio, .wav, .aiff]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL, String) -> Void
        init(onPick: @escaping (URL, String) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                let name = url.deletingPathExtension().lastPathComponent
                onPick(url, name)
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
