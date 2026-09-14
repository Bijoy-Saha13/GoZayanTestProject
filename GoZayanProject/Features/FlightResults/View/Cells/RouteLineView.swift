//
//  RouteLineView.swift
//  GoZayanProject
//

import UIKit

/// The route line on a flight card: open circles at both ends and one filled
/// dot per stop, clustered in the middle (Non-Stop → no dots, 2 Stop → two dots).
final class RouteLineView: UIView {

    var stopCount = 0 {
        didSet { setNeedsDisplay() }
    }

    private let endRadius: CGFloat = 4
    private let stopRadius: CGFloat = 4
    private let stopSpacing: CGFloat = 16
    private let lineWidth: CGFloat = 1.5

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        isAccessibilityElement = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: max(endRadius, stopRadius) * 2 + lineWidth)
    }

    override func draw(_ rect: CGRect) {
        let color = Theme.Colors.route
        let midY = bounds.midY
        let startX = bounds.minX + endRadius + lineWidth / 2
        let endX = bounds.maxX - endRadius - lineWidth / 2
        guard endX > startX else { return }

        color.setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: startX + endRadius, y: midY))
        line.addLine(to: CGPoint(x: endX - endRadius, y: midY))
        line.lineWidth = lineWidth
        line.stroke()

        for x in [startX, endX] {
            let circle = UIBezierPath(arcCenter: CGPoint(x: x, y: midY), radius: endRadius,
                                      startAngle: 0, endAngle: .pi * 2, clockwise: true)
            circle.lineWidth = lineWidth
            circle.stroke()
        }

        guard stopCount > 0 else { return }
        color.setFill()
        let available = endX - startX - (endRadius + stopRadius) * 2
        let spacing = min(stopSpacing, available / CGFloat(max(stopCount - 1, 1)))
        let firstX = bounds.midX - spacing * CGFloat(stopCount - 1) / 2
        for index in 0..<stopCount {
            let center = CGPoint(x: firstX + spacing * CGFloat(index), y: midY)
            UIBezierPath(arcCenter: center, radius: stopRadius,
                         startAngle: 0, endAngle: .pi * 2, clockwise: true).fill()
        }
    }
}
