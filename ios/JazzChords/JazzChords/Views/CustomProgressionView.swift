// Custom progressions — type any chord sequence (Autumn Leaves, All of Me, …),
// see it parsed, then drill it. Presets seed common standards. Parser is the
// ported engine parseProgression / PROGRESSION_PRESETS.

import SwiftUI
import MusicEngine

struct CustomProgressionView: View {
    @Environment(\.palette) private var palette
    @Environment(\.dismiss) private var dismiss

    @State private var raw = ""
    @State private var launch = false
    @State private var store = TrainerStore()

    private var parsed: [CustomChord] { parseProgression(raw) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.space4) {
                Text("Type a progression")
                    .font(Display.headline(20)).foregroundStyle(palette.text)

                TextField("e.g. Dm7 | G7 | CMaj7", text: $raw, axis: .vertical)
                    .lineLimit(2...4)
                    .padding(Theme.space3)
                    .glassCard()
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)

                // Parsed preview chips
                if !parsed.isEmpty {
                    FlowChips(items: parsed.map { $0.display }, color: palette.primary)
                    Button {
                        store.loadSettings()
                        store.startCustom(parsed)
                        launch = true
                    } label: {
                        Text("Drill \(parsed.count) chords")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.space4)
                            .background(palette.primary, in: RoundedRectangle(cornerRadius: Theme.radius))
                            .foregroundStyle(palette.primaryText)
                    }
                } else if !raw.isEmpty {
                    Text("No chords recognized yet — try forms like Dm7, BbMaj7, F#7.")
                        .font(.footnote).foregroundStyle(palette.textDim)
                }

                Text("Standards")
                    .font(Display.headline(18)).foregroundStyle(palette.text)
                    .padding(.top, Theme.space2)
                ForEach(PROGRESSION_PRESETS, id: \.name) { preset in
                    Button { raw = preset.raw } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name).font(.subheadline.weight(.medium)).foregroundStyle(palette.text)
                                Text(preset.tag).font(.caption).foregroundStyle(palette.textMuted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left.circle").foregroundStyle(palette.textDim)
                        }
                        .padding(Theme.space3)
                        .glassCard()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.space4)
        }
        .navigationTitle("Custom")
        .navigationBarTitleDisplayMode(.inline)
        .screenBackground()
        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        .fullScreenCover(isPresented: $launch) {
            NavigationStack {
                Group {
                    switch store.screen {
                    case .playing: TrainerPlayingView(store: store, onClose: { launch = false })
                    case .finished: TrainerFinishedView(store: store, onClose: { launch = false })
                    default: TrainerPlayingView(store: store, onClose: { launch = false })
                    }
                }
                .screenBackground()
            }
        }
    }
}

/// Simple wrapping chip row.
struct FlowChips: View {
    @Environment(\.palette) private var palette
    let items: [String]
    let color: Color

    var body: some View {
        // Lightweight wrap using a LazyVGrid of adaptive columns.
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 6)], alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, c in
                Text(c)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(palette.text)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(color.opacity(0.14), in: Capsule())
            }
        }
    }
}
