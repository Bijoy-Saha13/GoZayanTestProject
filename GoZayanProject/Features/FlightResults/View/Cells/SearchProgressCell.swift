//
//  SearchProgressCell.swift
//  GoZayanProject
//

import UIKit

/// Top of the loading state: an orange progress bar and the
/// "Hang tight!" message, as in the Figma loading frame.
final class SearchProgressCell: UICollectionViewCell {

    private let progressBar = IndeterminateProgressBar()
    private let messageLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        messageLabel.text = FlightResultsCopy.loadingMessage
        messageLabel.font = Theme.Fonts.loadingMessage
        messageLabel.textColor = Theme.Colors.onBackground
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontForContentSizeCategory = true

        isAccessibilityElement = true
        accessibilityLabel = "Loading flights. " + FlightResultsCopy.loadingMessage
        accessibilityTraits = .updatesFrequently

        [progressBar, messageLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            progressBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            progressBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            progressBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            progressBar.heightAnchor.constraint(equalToConstant: 6),

            messageLabel.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 28),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The API reports no real progress, so the fill eases towards 90% and holds:
/// it signals activity, not a percentage. Static at 40% with Reduce Motion.
private final class IndeterminateProgressBar: UIView {

    private let fillLayer = CALayer()
    private static let animationKey = "progress"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.Colors.progressTrack
        layer.cornerRadius = 3
        clipsToBounds = true
        isAccessibilityElement = false

        fillLayer.backgroundColor = Theme.Colors.progressFill.cgColor
        fillLayer.anchorPoint = CGPoint(x: 0, y: 0.5)
        layer.addSublayer(fillLayer)

        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(restartAnimation),
                           name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        center.addObserver(self, selector: #selector(restartAnimation),
                           name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillLayer.bounds = CGRect(origin: .zero, size: bounds.size)
        fillLayer.position = CGPoint(x: 0, y: bounds.midY)
        CATransaction.commit()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restartAnimation()
    }

    @objc private func restartAnimation() {
        fillLayer.removeAnimation(forKey: Self.animationKey)
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            fillLayer.transform = CATransform3DMakeScale(0.4, 1, 1)
            return
        }
        fillLayer.transform = CATransform3DMakeScale(0.9, 1, 1)
        let animation = CABasicAnimation(keyPath: "transform.scale.x")
        animation.fromValue = 0.05
        animation.toValue = 0.9
        animation.duration = 8
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fillLayer.add(animation, forKey: Self.animationKey)
    }
}
