import SwiftUI

// MARK: - Container

struct SplashContainerView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            ContentView()
            if showSplash {
                SplashView {
                    withAnimation(.easeInOut(duration: 0.55)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    var onComplete: () -> Void

    // Background
    @State private var bgOpacity: Double = 0

    // Ball
    @State private var ballScale: CGFloat = 0.04
    @State private var ballOpacity: Double = 1

    // Hole
    @State private var holePulse: CGFloat = 1.0

    // Ripples & sparkles (shown conditionally via trigger)
    @State private var showRipples = false
    @State private var showSparkles = false

    // Title
    @State private var titleOpacity: Double = 0
    @State private var titleY: CGFloat = 28
    @State private var subtitleOpacity: Double = 0

    private let bg   = Color(red: 0.05, green: 0.18, blue: 0.08)
    private let mid  = Color(red: 0.09, green: 0.34, blue: 0.15)

    var body: some View {
        ZStack {
            // ── Background ──────────────────────────────────────────────
            bg.ignoresSafeArea()

            // Mowing stripes
            MowingStripes()
                .ignoresSafeArea()
                .opacity(0.35)

            // Soft radial glow at centre
            RadialGradient(
                colors: [mid.opacity(0.9), mid.opacity(0)],
                center: .center, startRadius: 0, endRadius: 220
            )
            .frame(width: 440, height: 440)

            // ── Hole ─────────────────────────────────────────────────────
            ZStack {
                Circle()
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 62, height: 62)
                    .blur(radius: 5)

                Circle()
                    .fill(Color.black.opacity(0.92))
                    .frame(width: 48, height: 48)

                Circle()
                    .stroke(Color(white: 0.35), lineWidth: 1)
                    .frame(width: 48, height: 48)
            }
            .scaleEffect(holePulse)

            // ── Ripples ───────────────────────────────────────────────────
            if showRipples {
                ForEach(0..<3, id: \.self) { i in
                    RippleRing(delay: Double(i) * 0.13)
                }
            }

            // ── Sparkles ──────────────────────────────────────────────────
            if showSparkles {
                SparklesBurst()
            }

            // ── Ball shadow ───────────────────────────────────────────────
            Ellipse()
                .fill(Color.black.opacity(0.25))
                .frame(width: 38, height: 9)
                .blur(radius: 4)
                .offset(y: 22)
                .scaleEffect(ballScale)
                .opacity(ballOpacity * Double(min(ballScale * 3, 1)))

            // ── Golf ball ─────────────────────────────────────────────────
            GolfBallShape()
                .frame(width: 44, height: 44)
                .scaleEffect(ballScale)
                .opacity(ballOpacity)

            // ── Title ─────────────────────────────────────────────────────
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.gold.opacity(0.2))
                            .frame(width: 42, height: 42)
                        Image(systemName: "flag.fill")
                            .font(.title3)
                            .foregroundStyle(AppTheme.gold)
                    }
                    Text("GolfTrack")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Text("Dein persönlicher Golfbegleiter")
                    .font(.subheadline)
                    .foregroundStyle(Color(white: 1, opacity: 0.55))
                    .opacity(subtitleOpacity)
            }
            .offset(y: 160 + titleY)
            .opacity(titleOpacity)
        }
        .opacity(bgOpacity)
        .onAppear { runAnimation() }
    }

    private func runAnimation() {
        // Fade in
        withAnimation(.easeIn(duration: 0.25)) { bgOpacity = 1 }

        // Ball approaches (grows from tiny to full)
        withAnimation(.easeIn(duration: 0.85).delay(0.15)) { ballScale = 1.0 }

        // Ball sinks into hole
        withAnimation(.easeIn(duration: 0.32).delay(1.0)) {
            ballScale = 0.04
            ballOpacity = 0
        }

        // Hole pulses open, then back
        withAnimation(.easeOut(duration: 0.18).delay(1.05)) { holePulse = 1.22 }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(1.23)) { holePulse = 1.0 }

        // Ripples
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.18) { showRipples = true }

        // Sparkles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { showSparkles = true }

        // Title slides up
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72).delay(1.45)) {
            titleOpacity = 1
            titleY = 0
        }
        withAnimation(.easeOut(duration: 0.35).delay(1.75)) { subtitleOpacity = 1 }

        // Hand off to app
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) { onComplete() }
    }
}

// MARK: - Golf ball

private struct GolfBallShape: View {
    private let dimples: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
        ( 0,  -13, 3.6), ( 8,  -9, 3.0), (-8,  -9, 3.0),
        (13,   0,  3.0), (-13,  0, 3.0), ( 0,   0, 3.6),
        ( 8,   9,  3.0), (-8,   9, 3.0), ( 0,  13, 3.6),
        ( 5,  -4,  2.4), (-5,  -4, 2.4), ( 5,   4, 2.4), (-5,  4, 2.4),
    ]

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, Color(white: 0.86)],
                        center: UnitPoint(x: 0.33, y: 0.28),
                        startRadius: 0,
                        endRadius: 22
                    )
                )
            ForEach(dimples.indices, id: \.self) { i in
                Circle()
                    .fill(Color(white: 0.72).opacity(0.65))
                    .frame(width: dimples[i].r, height: dimples[i].r)
                    .offset(x: dimples[i].x, y: dimples[i].y)
            }
        }
    }
}

// MARK: - Ripple ring

private struct RippleRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.9
    @State private var opacity: Double = 0.55

    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 1.6)
            .frame(width: 50, height: 50)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 0.85).delay(delay)) {
                    scale = 4.2
                    opacity = 0
                }
            }
    }
}

// MARK: - Sparkles

private struct SparklesBurst: View {
    private let items: [(angle: Double, dist: CGFloat, symbol: String, color: Color)] = [
        (  0, 52, "sparkle",   .yellow),
        ( 60, 48, "star.fill", .white),
        (120, 52, "sparkle",   .yellow),
        (180, 50, "star.fill", .white),
        (240, 52, "sparkle",   .yellow),
        (300, 48, "star.fill", .white),
    ]
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0.9

    var body: some View {
        ZStack {
            ForEach(items.indices, id: \.self) { i in
                let item = items[i]
                let rad  = item.angle * .pi / 180
                Image(systemName: item.symbol)
                    .font(item.symbol == "sparkle" ? .callout : .caption2)
                    .foregroundStyle(item.color)
                    .offset(
                        x: cos(rad) * item.dist * scale,
                        y: sin(rad) * item.dist * scale
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.55)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Mowing stripes

private struct MowingStripes: View {
    var body: some View {
        Canvas { ctx, size in
            let w: CGFloat = 44
            var x: CGFloat = 0
            var col = false
            while x < size.width {
                if col {
                    var p = Path()
                    p.addRect(CGRect(x: x, y: 0, width: w, height: size.height))
                    ctx.fill(p, with: .color(Color.white.opacity(0.045)))
                }
                x += w
                col.toggle()
            }
        }
    }
}
