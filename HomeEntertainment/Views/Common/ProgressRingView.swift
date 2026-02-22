import SwiftUI

struct ProgressRingView: View {
    let percent: Double
    var size: CGFloat = 48
    var lineWidth: CGFloat = 5

    private var progress: Double { min(max(percent / 100.0, 0), 1) }

    private var ringColor: Color {
        if progress >= 1.0 { return .green }
        if progress >= 0.5 { return Theme.accent }
        return Theme.accent.opacity(0.8)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.15), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            Text("\(Int(percent))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(ringColor)
        }
        .frame(width: size, height: size)
    }
}
