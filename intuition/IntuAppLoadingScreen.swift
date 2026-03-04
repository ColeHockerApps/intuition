import SwiftUI
import Combine

struct IntuAppLoadingScreen: View {

    @State private var t: Double = 0
    @State private var pulse: Bool = false
    @State private var sweep: Double = 0
    @State private var drift: Double = 0

    var body: some View {
        ZStack {
            background

            GridScan(t: t)
                .opacity(0.55)
                .blendMode(.screen)

            OrbitalCoins(t: t, drift: drift)
                .opacity(0.92)
                .blendMode(.screen)

            VStack(spacing: 16) {
                LedgerCore(t: t, pulse: pulse, sweep: sweep)
                    .frame(width: 210, height: 210)

                Text("Loading")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(pulse ? 0.92 : 0.78))
                    .scaleEffect(pulse ? 1.02 : 0.98)
                    .opacity(0.98)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 26)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) { t = 1 }
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 2.6).repeatForever(autoreverses: false)) { sweep = 1 }
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) { drift = 1 }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.04, blue: 0.07),
                Color(red: 0.05, green: 0.06, blue: 0.12),
                Color(red: 0.02, green: 0.03, blue: 0.06)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct GridScan: View {

    let t: Double

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let step = max(18, s / 14)
            let phase = t * .pi * 2

            Canvas { ctx, size in
                let cols = Int(size.width / step) + 3
                let rows = Int(size.height / step) + 3

                for r in 0..<rows {
                    for c in 0..<cols {
                        let x = CGFloat(c) * step
                        let y = CGFloat(r) * step

                        let fx = Double(c) * 0.33
                        let fy = Double(r) * 0.27
                        let w = 0.5 + 0.5 * sin(phase + fx + fy)

                        let a = 0.02 + 0.10 * w
                        let col = Color.white.opacity(a)

                        var p = Path()
                        p.addRoundedRect(
                            in: CGRect(
                                x: x - step * 0.40,
                                y: y - step * 0.40,
                                width: step * 0.80,
                                height: step * 0.80
                            ),
                            cornerSize: CGSize(width: 7, height: 7),
                            style: .continuous
                        )

                        ctx.fill(p, with: .color(col))
                    }
                }

                let scanY = CGFloat((0.5 + 0.5 * sin(phase * 0.7)) * Double(size.height))
                var scan = Path()
                scan.addRoundedRect(
                    in: CGRect(x: -40, y: scanY - 10, width: size.width + 80, height: 20),
                    cornerSize: CGSize(width: 16, height: 16),
                    style: .continuous
                )
                ctx.addFilter(.blur(radius: 8))
                ctx.fill(scan, with: .color(Color.white.opacity(0.08)))
            }
        }
        .allowsHitTesting(false)
    }
}

private struct OrbitalCoins: View {

    let t: Double
    let drift: Double

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height
            let phase = t * .pi * 2

            ZStack {
                CoinBubble(
                    symbol: "₽",
                    x: w * 0.20,
                    y: h * 0.22,
                    size: 132,
                    wobble: CGFloat(sin(phase * 0.85)) * 16,
                    drift: CGFloat(cos(drift * .pi * 2)) * 10,
                    a: Color(red: 0.42, green: 0.86, blue: 0.72),
                    b: Color(red: 0.20, green: 0.55, blue: 0.42)
                )

                CoinBubble(
                    symbol: "$",
                    x: w * 0.82,
                    y: h * 0.26,
                    size: 112,
                    wobble: CGFloat(cos(phase * 0.95)) * 14,
                    drift: CGFloat(sin(drift * .pi * 2)) * 12,
                    a: Color(red: 0.46, green: 0.78, blue: 0.98),
                    b: Color(red: 0.34, green: 0.50, blue: 0.92)
                )

                CoinBubble(
                    symbol: "€",
                    x: w * 0.22,
                    y: h * 0.78,
                    size: 124,
                    wobble: CGFloat(sin(phase * 1.05 + 1.1)) * 15,
                    drift: CGFloat(cos(drift * .pi * 2 + 1.6)) * 11,
                    a: Color(red: 0.98, green: 0.72, blue: 0.38),
                    b: Color(red: 0.80, green: 0.44, blue: 0.12)
                )

                CoinBubble(
                    symbol: "¥",
                    x: w * 0.80,
                    y: h * 0.78,
                    size: 96,
                    wobble: CGFloat(cos(phase * 1.00 + 0.7)) * 13,
                    drift: CGFloat(sin(drift * .pi * 2 + 2.1)) * 10,
                    a: Color(red: 0.98, green: 0.52, blue: 0.70),
                    b: Color(red: 0.72, green: 0.26, blue: 0.44)
                )
            }
        }
        .blur(radius: 0.6)
        .allowsHitTesting(false)
    }
}

private struct CoinBubble: View {

    let symbol: String
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let wobble: CGFloat
    let drift: CGFloat
    let a: Color
    let b: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            a.opacity(0.78),
                            b.opacity(0.24),
                            Color.clear
                        ],
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: size * 0.70
                    )
                )
                .overlay(
                    Circle().stroke(Color.white.opacity(0.14), lineWidth: 1.4)
                )
                .shadow(color: Color.black.opacity(0.40), radius: 26, y: 18)

            Text(symbol)
                .font(.system(size: size * 0.46, weight: .bold, design: .rounded))
                .foregroundColor(Color.white.opacity(0.92))
                .shadow(color: Color.white.opacity(0.10), radius: 8)
        }
        .frame(width: size, height: size)
        .position(x: x + wobble + drift, y: y + drift - wobble * 0.22)
    }
}

private struct LedgerCore: View {

    let t: Double
    let pulse: Bool
    let sweep: Double

    var body: some View {
        GeometryReader { g in
            let s = min(g.size.width, g.size.height)
            let phase = t * .pi * 2

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.10),
                                Color.white.opacity(0.03),
                                Color.black.opacity(0.14)
                            ],
                            center: .topLeading,
                            startRadius: 8,
                            endRadius: s * 0.66
                        )
                    )
                    .overlay(
                        Circle().stroke(Color.white.opacity(0.16), lineWidth: 1.6)
                    )
                    .shadow(color: Color.black.opacity(0.48), radius: 30, y: 18)

                RingTicks(phase: phase)
                    .padding(s * 0.12)
                    .opacity(0.9)

                LedgerBars(phase: phase, pulse: pulse)
                    .padding(s * 0.26)
                    .opacity(0.95)

                SweepHighlight(phase: sweep)
                    .clipShape(Circle())
                    .blendMode(.screen)
                    .opacity(0.55)
            }
            .scaleEffect(pulse ? 1.02 : 0.985)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulse)
        }
        .allowsHitTesting(false)
    }
}

private struct RingTicks: View {

    let phase: Double

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = min(size.width, size.height) / 2

            for i in 0..<54 {
                let k = Double(i) / 54.0
                let a = k * .pi * 2
                let w = 0.35 + 0.65 * (0.5 + 0.5 * sin(phase + k * 9.0))

                let len = r * (i % 6 == 0 ? 0.18 : 0.10)
                let lw: CGFloat = (i % 6 == 0) ? 2.2 : 1.3

                let p0 = CGPoint(x: c.x + CGFloat(cos(a)) * (r - len), y: c.y + CGFloat(sin(a)) * (r - len))
                let p1 = CGPoint(x: c.x + CGFloat(cos(a)) * (r - 2), y: c.y + CGFloat(sin(a)) * (r - 2))

                var path = Path()
                path.move(to: p0)
                path.addLine(to: p1)

                ctx.stroke(path, with: .color(Color.white.opacity(0.08 + 0.18 * w)), lineWidth: lw)
            }
        }
    }
}

private struct LedgerBars: View {

    let phase: Double
    let pulse: Bool

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let h = g.size.height

            let a0 = 0.5 + 0.5 * sin(phase * 0.9)
            let a1 = 0.5 + 0.5 * sin(phase * 1.1 + 1.2)
            let a2 = 0.5 + 0.5 * sin(phase * 1.0 + 2.3)
            let a3 = 0.5 + 0.5 * sin(phase * 1.2 + 0.4)

            let values = [a0, a1, a2, a3].map { 0.22 + 0.70 * $0 }

            let barW = w * 0.12
            let gap = w * 0.08
            let total = barW * 4 + gap * 3
            let x0 = (w - total) / 2

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                ForEach(0..<4, id: \.self) { i in
                    let val = values[i]
                    let bh = h * CGFloat(val)
                    let x = x0 + CGFloat(i) * (barW + gap) + barW / 2

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.18),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: barW, height: bh)
                        .position(x: x, y: h - bh / 2)
                        .shadow(color: Color.white.opacity(pulse ? 0.10 : 0.06), radius: 10)
                }
            }
        }
    }
}

private struct SweepHighlight: View {

    let phase: Double

    var body: some View {
        GeometryReader { g in
            let w = g.size.width
            let x = (phase - floor(phase)) * 2.0 - 0.5

            LinearGradient(
                colors: [
                    Color.white.opacity(0.0),
                    Color.white.opacity(0.16),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: w * 0.26)
            .rotationEffect(.degrees(18))
            .offset(x: CGFloat(x) * w)
            .blur(radius: 2.2)
        }
    }
}
