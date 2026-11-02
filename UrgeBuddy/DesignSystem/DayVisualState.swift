import SwiftUI

/// How a calendar day looks. Shape and color both carry the state.
enum DayVisualState: Equatable, CaseIterable {
    case confirmedFree
    case presumedFree
    case slipped
    case habitDone
    case habitPartial
    case missed
    case withinLimit
    case overLimit
    case notLogged
    case todayPending
    case inactive

    var accessibilityName: String {
        switch self {
        case .confirmedFree: "free"
        case .presumedFree: "free, not confirmed"
        case .slipped: "slip"
        case .habitDone: "done"
        case .habitPartial: "partly done"
        case .missed: "not done"
        case .withinLimit: "within limit"
        case .overLimit: "over limit"
        case .notLogged: "not logged"
        case .todayPending: "not checked in yet"
        case .inactive: "outside this stretch"
        }
    }

    var tint: Color {
        switch self {
        case .confirmedFree, .presumedFree, .withinLimit: .tbBrand
        case .slipped, .overLimit: .tbSlip
        case .habitDone, .habitPartial: .tbHabit
        case .missed, .notLogged, .todayPending: .tbTextSecondary
        case .inactive: .tbSurfaceMuted
        }
    }

    var shape: DayMarkShape {
        switch self {
        case .confirmedFree, .withinLimit: .solidCircle
        case .presumedFree: .ring
        case .slipped, .overLimit: .triangle
        case .habitDone: .solidRoundedSquare
        case .habitPartial: .hollowRoundedSquare
        case .missed, .notLogged: .hollowSquare
        case .todayPending: .dashedRing
        case .inactive: .muted
        }
    }
}

enum DayMarkShape: Equatable {
    case solidCircle
    case ring
    case triangle
    case solidRoundedSquare
    case hollowRoundedSquare
    case hollowSquare
    case dashedRing
    case muted
}

struct DayMark: View {
    var state: DayVisualState
    var size: CGFloat = 16

    var body: some View {
        mark
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var mark: some View {
        switch state.shape {
        case .solidCircle:
            Circle().fill(state.tint)
        case .ring:
            Circle().stroke(state.tint, lineWidth: 2)
        case .triangle:
            UpTriangle().fill(state.tint)
        case .solidRoundedSquare:
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous).fill(state.tint)
        case .hollowRoundedSquare:
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .stroke(state.tint, lineWidth: 2.5)
        case .hollowSquare:
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .stroke(state.tint, lineWidth: 2)
        case .dashedRing:
            Circle().stroke(state.tint, style: StrokeStyle(lineWidth: 2, dash: [2, 2]))
        case .muted:
            Circle().fill(state.tint)
        }
    }
}

struct UpTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
