//
//  DashedLineView.swift
//  GoZayanProject
//

import UIKit

/// Horizontal dashed rule, as used between a flight's route and its price.
final class DashedLineView: UIView {

    private let shapeLayer = CAShapeLayer()

    init(color: UIColor, dashPattern: [NSNumber] = [4, 3]) {
        super.init(frame: .zero)
        isAccessibilityElement = false
        shapeLayer.strokeColor = color.cgColor
        shapeLayer.lineDashPattern = dashPattern
        layer.addSublayer(shapeLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 1)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: bounds.midY))
        path.addLine(to: CGPoint(x: bounds.width, y: bounds.midY))
        shapeLayer.lineWidth = bounds.height
        shapeLayer.frame = bounds
        shapeLayer.path = path.cgPath
    }
}
