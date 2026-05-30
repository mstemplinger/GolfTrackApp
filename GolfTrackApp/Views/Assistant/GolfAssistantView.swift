import SwiftUI

struct GolfAssistantView: View {
    @StateObject private var service = ElevenLabsService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                orbArea
                statusLabel
                Spacer()
                transcriptSection
                controlButton
                    .padding(.bottom, 32)
            }
        }
        .alert("Fehler", isPresented: Binding(
            get: { service.errorMessage != nil },
            set: { if !$0 { service.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { service.errorMessage = nil }
        } message: {
            Text(service.errorMessage ?? "")
        }
        .onDisappear {
            Task { await service.stop() }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.gold)
            }
            Spacer()
            VStack(spacing: 2) {
                Text("Caddy")
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Golf-Assistent")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            statusDot
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 4)
                    .scaleEffect(service.status == .connected ? 1.6 : 1)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true),
                               value: service.status == .connected)
            )
    }

    // MARK: - Orb

    private var orbArea: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { i in
                orbRing(index: i)
            }
            orbCore
        }
        .frame(width: 200, height: 200)
        .padding(.bottom, 16)
    }

    private func orbRing(index: Int) -> some View {
        let scale: CGFloat = service.isActive ? 1 + CGFloat(index) * 0.25 : 1
        let opacity: Double = service.isActive ? 0.15 - Double(index) * 0.04 : 0
        return Circle()
            .fill(AppTheme.gold.opacity(opacity))
            .scaleEffect(scale)
            .animation(
                .easeInOut(duration: 1.2 + Double(index) * 0.3)
                    .repeatForever(autoreverses: true)
                    .delay(Double(index) * 0.2),
                value: service.isActive
            )
    }

    private var orbCore: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            AppTheme.gold.opacity(orbIntensity),
                            Color(red: 0.1, green: 0.25, blue: 0.1)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 70
                    )
                )
                .frame(width: 120, height: 120)
                .shadow(color: AppTheme.gold.opacity(0.4), radius: service.isActive ? 20 : 5)
                .animation(.easeInOut(duration: 0.8), value: service.isActive)

            if service.mode == .speaking && service.status == .connected {
                waveBars
            } else {
                Image(systemName: service.isActive ? "waveform" : "mic.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(service.isActive ? AppTheme.gold : .white.opacity(0.4))
                    .animation(.easeInOut(duration: 0.3), value: service.isActive)
            }
        }
    }

    private var orbIntensity: Double {
        switch service.status {
        case .connected:    return service.isMuted ? 0.2 : (service.mode == .speaking ? 0.9 : 0.6)
        case .connecting:   return 0.4
        default:            return 0.15
        }
    }

    private var waveBars: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppTheme.gold)
                    .frame(width: 4, height: CGFloat.random(in: 12...36))
                    .animation(
                        .easeInOut(duration: 0.4 + Double(i) * 0.1)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.08),
                        value: service.mode
                    )
            }
        }
    }

    // MARK: - Status Label

    private var statusLabel: some View {
        Group {
            if service.status == .connected {
                Text(service.mode.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.gold)
            } else {
                Text(service.status.label)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: service.status)
        .animation(.easeInOut(duration: 0.3), value: service.mode)
    }

    // MARK: - Transcript

    private var transcriptSection: some View {
        Group {
            if !service.messages.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(service.messages) { msg in
                                messageBubble(msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 200)
                    .onChange(of: service.messages.count) { _, _ in
                        if let last = service.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white.opacity(0.05))
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else if service.status == .connected {
                Text("Stelle mir eine Frage über Golf…")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(.bottom, 24)
            }
        }
    }

    private func messageBubble(_ msg: ChatMessage) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 40) }
            Text(msg.text)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(msg.role == .assistant
                              ? AppTheme.gold.opacity(0.2)
                              : Color.white.opacity(0.1))
                )
            if msg.role == .assistant { Spacer(minLength: 40) }
        }
    }

    // MARK: - Control Button

    private var controlButton: some View {
        HStack(spacing: 12) {
            // Mute – nur sichtbar wenn verbunden
            if service.status == .connected {
                Button { service.toggleMute() } label: {
                    Image(systemName: service.isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(service.isMuted ? .white : AppTheme.gold)
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(service.isMuted
                                      ? Color.white.opacity(0.18)
                                      : AppTheme.gold.opacity(0.12))
                        )
                        .overlay(
                            Circle()
                                .stroke(service.isMuted
                                        ? Color.white.opacity(0.35)
                                        : AppTheme.gold.opacity(0.35),
                                        lineWidth: 1.5)
                        )
                }
                .transition(.scale.combined(with: .opacity))
            }

            // Start / Stop
            Button {
                Task {
                    if service.isActive {
                        await service.stop()
                    } else {
                        await service.start()
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: service.isActive ? "stop.circle.fill" : "mic.circle.fill")
                        .font(.title3)
                    Text(service.isActive ? "Gespräch beenden" : "Gespräch starten")
                        .font(.headline)
                }
                .foregroundStyle(service.isActive ? .red : .black)
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(service.isActive ? Color.red.opacity(0.15) : AppTheme.gold)
                )
                .overlay(
                    Capsule()
                        .stroke(service.isActive ? Color.red.opacity(0.4) : .clear, lineWidth: 1.5)
                )
            }
            .disabled(service.status == .disconnecting)
        }
        .animation(.easeInOut(duration: 0.25), value: service.isActive)
        .animation(.spring(duration: 0.3), value: service.status == .connected)
        .padding(.horizontal, 24)
    }

    private var statusColor: Color {
        switch service.status {
        case .connected:    return .green
        case .connecting:   return .yellow
        case .disconnecting: return .orange
        case .disconnected: return .gray
        }
    }
}

#Preview {
    GolfAssistantView()
        .preferredColorScheme(.dark)
}
