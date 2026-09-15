import SwiftUI

struct CountdownRing: View {
    var daysRemaining: Int
    var total: Int = 60

    var progress: Double {
        guard total > 0 else { return 0 }
        return min(1, max(0, Double(daysRemaining) / Double(total)))
    }

    var color: Color {
        if daysRemaining < 0 { return .red }
        if daysRemaining <= 7 { return .orange }
        if daysRemaining <= 21 { return Color(hex: "FF9F0A") }
        return .green
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            VStack(spacing: 0) {
                Text("\(max(0, daysRemaining))")
                    .font(.title2.bold())
                    .monospacedDigit()
                Text(daysRemaining == 1 ? "day" : "days")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(daysRemaining) days until deadline")
    }
}

struct JarProgressBar: View {
    var progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                    Capsule()
                        .fill(Color.green)
                        .frame(width: max(8, geo.size.width * progress))
                }
            }
            .frame(height: 12)
            Text("\(Int((progress * 100).rounded()))%")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tax jar is \(Int((progress * 100).rounded()))% full")
    }
}

struct ConfettiView: View {
    var active: Bool
    var onFinished: () -> Void

    private struct Particle: Identifiable {
        let id = UUID()
        let x: CGFloat
        let delay: Double
        let color: Color
        let size: CGFloat
        let rotation: Double
    }

    private let particles: [Particle] = (0..<60).map { i in
        Particle(
            x: CGFloat.random(in: 0...1),
            delay: Double.random(in: 0...0.4),
            color: [Color.green, Color(hex: "FF9F0A"), .blue, .pink, .yellow][i % 5],
            size: CGFloat.random(in: 6...12),
            rotation: Double.random(in: 0...360))
    }

    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.color)
                    .frame(width: p.size, height: p.size * 1.6)
                    .rotationEffect(.degrees(p.rotation))
                    .position(x: geo.size.width * p.x, y: active ? geo.size.height + 40 : -40)
                    .animation(.easeIn(duration: 1.6).delay(p.delay), value: active)
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
        .onChange(of: active) { _, isActive in
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { onFinished() }
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var value: UInt64 = 0
        scanner.scanHexInt64(&value)
        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }
}

struct GlassCard<Content: View>: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4))
    }
}

extension View {
    func screenMaxWidth() -> some View {
        frame(maxWidth: 720).frame(maxWidth: .infinity)
    }
}
