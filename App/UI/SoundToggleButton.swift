import SwiftUI

/// One explicit state and one icon shared by Home and Audio settings.
struct SoundToggleButton: View {
    @Bindable var audio: AudioService
    var compact = false
    var identifier = "soundToggle"

    var body: some View {
        Button { audio.isMuted.toggle() } label: {
            HStack(spacing: 12) {
                Image(systemName: audio.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 21, weight: .bold))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 26)
                if !compact {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(audio.isMuted ? "SOUND OFF" : "SOUND ON")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text(audio.isMuted ? "Tap to unmute" : "Mute all sounds")
                            .font(.caption).foregroundStyle(.white.opacity(0.75))
                    }
                    Spacer(minLength: 0)
                }
            }
            .padding(compact ? 13 : 14)
            .foregroundStyle(audio.isMuted ? CrocoTheme.orange : CrocoTheme.lime)
            .background(CrocoTheme.ink.opacity(0.94), in: RoundedRectangle(cornerRadius: compact ? 16 : 18))
            .overlay(RoundedRectangle(cornerRadius: compact ? 16 : 18)
                .stroke((audio.isMuted ? CrocoTheme.orange : CrocoTheme.lime).opacity(0.6), lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityLabel(audio.isMuted ? "Unmute all sounds" : "Mute all sounds")
        .accessibilityValue(audio.isMuted ? "Sound off" : "Sound on")
    }
}
