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
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            orbView(time: t)
        }
        .frame(width: 220, height: 220)
        .padding(.bottom, 8)
    }

    private func orbView(time t: Double) -> some View {
        let pulse = service.isActive
            ? 1.0 + 0.06 * sin(t * (service.mode == .speaking ? 6 : 2.5))
            : 1.0
        let glowRadius: CGFloat = service.isActive ? (service.mode == .speaking ? 36 : 22) : 8
        let glowOpacity: Double = service.isMuted ? 0.1 : (service.isActive ? 0.55 : 0.15)

        return ZStack {
            // Äußerer Glow-Ring
            Circle()
                .fill(AppTheme.gold.opacity(glowOpacity * 0.3))
                .frame(width: 190, height: 190)
                .blur(radius: 18)

            // Orb-Körper: Basis
            Circle()
                .fill(Color(red: 0.06, green: 0.14, blue: 0.08))
                .frame(width: 150, height: 150)

            // Rotation-Gradient (ElevenLabs-Stil)
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            AppTheme.gold.opacity(0.9),
                            Color(red: 0.06, green: 0.14, blue: 0.08),
                            AppTheme.gold.opacity(0.15),
                            Color(red: 0.06, green: 0.14, blue: 0.08),
                            AppTheme.gold.opacity(0.7),
                            Color(red: 0.06, green: 0.14, blue: 0.08),
                            AppTheme.gold.opacity(0.9),
                        ],
                        center: .center,
                        startAngle: .degrees(t * (service.mode == .speaking ? 120 : 40)),
                        endAngle: .degrees(t * (service.mode == .speaking ? 120 : 40) + 360)
                    )
                )
                .frame(width: 150, height: 150)
                .blur(radius: 6)

            // Radialer Glanz (3D-Effekt)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            .white.opacity(0.25),
                            AppTheme.gold.opacity(0.1),
                            .clear
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: 70
                    )
                )
                .frame(width: 150, height: 150)

            // Dunkle Überlagerung an Rand
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.clear, Color(red: 0.04, green: 0.10, blue: 0.05).opacity(0.85)],
                        center: .center,
                        startRadius: 45,
                        endRadius: 75
                    )
                )
                .frame(width: 150, height: 150)

            // Mute-Slash
            if service.isMuted {
                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .scaleEffect(pulse)
        .shadow(color: AppTheme.gold.opacity(glowOpacity), radius: glowRadius, x: 0, y: 0)
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
