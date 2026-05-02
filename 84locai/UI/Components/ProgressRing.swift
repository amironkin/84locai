import SwiftUI

struct ProgressRing: View {
    var progress: Double // 0.0 – 1.0
    var lineWidth: CGFloat = 4
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appBorder, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient.primaryGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(width: size, height: size)
    }
}

struct DownloadProgressBar: View {
    var progress: Double
    var label: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(label)
                    .font(.appCaption)
                    .foregroundStyle(Color.appTextSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.appCaption)
                    .foregroundStyle(Color.appPrimaryLight)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: Radius.full)
                        .fill(Color.appBorder)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: Radius.full)
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: geo.size.width * progress, height: 4)
                        .animation(.linear(duration: 0.2), value: progress)
                }
            }
            .frame(height: 4)
        }
    }
}
