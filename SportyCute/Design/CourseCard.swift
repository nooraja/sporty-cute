import SwiftUI

struct CourseCard: View {
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("SAMPLE COURSE", systemImage: "location.fill")
                .font(Theme.label)
                .foregroundStyle(Theme.lime)

            CourseDrawing()
                .frame(height: 138)
                .accessibilityHidden(true)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sanur Coast").font(Theme.display(.title))
                    Text("BALI, INDONESIA").font(Theme.label).foregroundStyle(Theme.lavender)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("10K").font(Theme.display(.title))
                    Text("\(count) CUES").font(Theme.label).foregroundStyle(Theme.lavender)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Theme.violet, in: RoundedRectangle(cornerRadius: 25))
    }
}

private struct CourseDrawing: View {
    var body: some View {
        Canvas { graphics, size in
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
                CGPoint(x: x * size.width, y: y * size.height)
            }

            for row in 0..<9 {
                let y = CGFloat(row) / 8
                var contour = Path()
                contour.move(to: point(0, y))
                contour.addCurve(
                    to: point(1, y - 0.13),
                    control1: point(0.34, y - 0.36),
                    control2: point(0.65, y + 0.39)
                )
                graphics.stroke(contour, with: .color(Theme.lavender.opacity(0.19)), lineWidth: 1)
            }

            let start = point(0.08, 0.77)
            let middle = point(0.47, 0.52)
            let finish = point(0.9, 0.23)
            var route = Path()
            route.move(to: start)
            route.addCurve(to: middle, control1: point(0.23, 0.95), control2: point(0.24, 0.17))
            route.addCurve(to: finish, control1: point(0.74, 0.96), control2: point(0.66, 0.06))
            graphics.stroke(route, with: .color(Theme.lime.opacity(0.2)), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            graphics.stroke(route, with: .color(Theme.lime), style: StrokeStyle(lineWidth: 4, lineCap: .round))

            for (position, symbol) in [(start, "bolt.fill"), (middle, "waveform"), (finish, "heart.fill")] {
                let dot = CGRect(x: position.x - 15, y: position.y - 15, width: 30, height: 30)
                graphics.fill(Path(ellipseIn: dot), with: .color(Theme.lime))
                graphics.draw(
                    Text(Image(systemName: symbol)).font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.ink),
                    at: position
                )
            }
        }
    }
}
