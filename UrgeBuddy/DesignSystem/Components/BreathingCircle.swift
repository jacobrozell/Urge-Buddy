import SwiftUI

struct BreathingCircle: View {
    var inhale: Double = 4
    var exhale: Double = 6
    var maxDiameter: CGFloat = 280
    var progress: Double?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var origin = Date()

    var body: some View {
        Group {
            if reduceMotion {
                Text("Breathe in for \(whole(inhale)) seconds. Breathe out for \(whole(exhale)).")
                    .font(.title2)
                    .foregroundStyle(Color.tbOnCalm)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let sample = BreathSample(date: context.date, origin: origin, inhale: inhale, exhale: exhale)
                    ZStack {
                        ripples(sample)
                        glow(sample)
                        orb(sample)
                        Text(sample.cue)
                            .font(.title2)
                            .foregroundStyle(Color.tbOnCalm)
                            .padding(Spacing.l)
                            .multilineTextAlignment(.center)
                            .opacity(sample.cueOpacity)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: maxDiameter, maxHeight: maxDiameter)
                    .overlay {
                        if let progress {
                            ring(progress)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Breathing guide. Breathe in for \(whole(inhale)) seconds, then out for \(whole(exhale)).")
        .onAppear { origin = Date() }
    }

    private func glow(_ sample: BreathSample) -> some View {
        Circle()
            .fill(Color.tbBrand.opacity(0.14 + 0.22 * sample.amount))
            .blur(radius: 28)
            .scaleEffect(0.62 + 0.3 * sample.amount)
    }

    private func orb(_ sample: BreathSample) -> some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color.tbCalm, location: 0),
                            .init(color: Color.tbCalm, location: 0.42),
                            .init(color: Color.tbBrand.opacity(0.18 + 0.22 * sample.amount), location: 0.68),
                            .init(color: Color.tbOnCalm.opacity(0.1 + 0.12 * sample.amount), location: 0.84),
                            .init(color: Color.tbOnCalm.opacity(0), location: 1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: maxDiameter / 2
                    )
                )
            Circle()
                .stroke(Color.tbOnCalm.opacity(0.22 + 0.28 * sample.amount), lineWidth: 2)
                .padding(maxDiameter * 0.02)
        }
        .scaleEffect(0.58 + 0.36 * sample.amount)
        .shadow(color: Color.tbBrand.opacity(0.28 * sample.amount), radius: 16)
    }

    private func ripples(_ sample: BreathSample) -> some View {
        ForEach(0..<3, id: \.self) { index in
            let ripple = (sample.elapsed / sample.cycle + Double(index) / 3)
                .truncatingRemainder(dividingBy: 1)
            Circle()
                .stroke(Color.tbOnCalm.opacity(0.2 * (1 - ripple)), lineWidth: 1.5)
                .scaleEffect(0.5 + ripple * 0.5)
        }
    }

    private func ring(_ progress: Double) -> some View {
        ZStack {
            Circle()
                .stroke(Color.tbOnCalm.opacity(0.15), lineWidth: 3)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(Color.tbOnCalm, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .urgeBuddyAnimation(.linear(duration: 1), value: progress, reduceMotion: reduceMotion)
        }
        .padding(2)
    }

    private func whole(_ value: Double) -> Int {
        Int(value.rounded())
    }
}

/// A slow color field for the ride screen. Stays dark enough for white text.
/// The top band is solid Calm so the close control and status area are not tinted.
struct RideAtmosphere: View {
    var body: some View {
        Color.tbCalm
            .overlay {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    MeshGradient(width: 3, height: 3, points: points(t), colors: colors)
                }
                .allowsHitTesting(false)
            }
            .overlay(alignment: .top) {
                LinearGradient(
                    stops: [
                        .init(color: Color.tbCalm, location: 0),
                        .init(color: Color.tbCalm, location: 0.62),
                        .init(color: Color.tbCalm.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                .allowsHitTesting(false)
            }
            .accessibilityHidden(true)
    }

    private var colors: [Color] {
        [
            Color.tbCalm,
            Color.tbCalm,
            Color.tbCalm,
            Color.tbCalm,
            Color.tbBrand.opacity(0.28),
            Color.tbCalm,
            Color.tbCalm,
            Color.tbBrand.opacity(0.16),
            Color.tbCalm
        ]
    }

    /// Corners stay pinned. Interior points drift so the wash moves without exposing gaps.
    private func points(_ t: TimeInterval) -> [SIMD2<Float>] {
        func p(_ x: Double, _ y: Double) -> SIMD2<Float> {
            SIMD2(Float(x), Float(y))
        }
        let drift = 0.045 * sin(t / 13)
        let sway = 0.04 * cos(t / 17)
        return [
            p(0, 0), p(0.5, 0), p(1, 0),
            p(0, 0.5), p(0.5 + sway, 0.48 + drift), p(1, 0.5),
            p(0, 1), p(0.5, 1), p(1, 1)
        ]
    }
}

private struct BreathSample {
    var amount: Double
    var cue: String
    var cueOpacity: Double
    var elapsed: TimeInterval
    var cycle: TimeInterval

    init(date: Date, origin: Date, inhale: Double, exhale: Double) {
        let cycle = max(inhale + exhale, 0.001)
        let elapsed = max(0, date.timeIntervalSince(origin))
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        let inhaling = t < inhale
        let phase = inhaling ? t : t - inhale
        let duration = max(inhaling ? inhale : exhale, 0.001)
        let eased = Self.smoothstep(phase / duration)
        self.amount = inhaling ? eased : 1 - eased
        self.cue = inhaling ? "Breathe in" : "Breathe out"
        self.cueOpacity = min(1, phase / 0.55)
        self.elapsed = elapsed
        self.cycle = cycle
    }

    private static func smoothstep(_ u: Double) -> Double {
        let x = min(max(u, 0), 1)
        return x * x * (3 - 2 * x)
    }
}

#Preview("Light") { BreathingCircle().padding().background(Color.tbCalm) }
#Preview("Timer ring") { BreathingCircle(progress: 0.6).padding().background(Color.tbCalm) }
#Preview("Dark") { BreathingCircle().padding().background(Color.tbCalm).preferredColorScheme(.dark) }
#Preview("AX3") { BreathingCircle().padding().background(Color.tbCalm).dynamicTypeSize(.accessibility3) }
#Preview("Landscape", traits: .landscapeLeft) { BreathingCircle().padding().background(Color.tbCalm) }
