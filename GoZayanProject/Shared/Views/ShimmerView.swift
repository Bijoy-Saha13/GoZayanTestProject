//
//  ShimmerView.swift
//  GoZayanProject
//

import UIKit

/// A moving highlight laid over skeleton placeholders.
/// Place it on top of the bones and let the host clip to its bounds.
/// Honours Reduce Motion by showing static placeholders only (FR-03a).
final class ShimmerView: UIView {

    private let gradientLayer = CAGradientLayer()
    private static let animationKey = "shimmer"

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isAccessibilityElement = false

        let highlight = Theme.Colors.shimmerHighlight.cgColor
        let clear = Theme.Colors.shimmerHighlight.withAlphaComponent(0).cgColor
        gradientLayer.colors = [clear, highlight, clear]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(updateAnimation),
                           name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        // Core Animation drops running animations when the app is backgrounded.
        center.addObserver(self, selector: #selector(updateAnimation),
                           name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        gradientLayer.frame = bounds
        CATransaction.commit()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateAnimation()
    }

    @objc private func updateAnimation() {
        gradientLayer.removeAnimation(forKey: Self.animationKey)
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            gradientLayer.isHidden = true
            return
        }
        gradientLayer.isHidden = false

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.4
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: Self.animationKey)
    }
}
