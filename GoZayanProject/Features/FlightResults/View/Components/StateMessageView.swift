//
//  StateMessageView.swift
//  GoZayanProject
//

import UIKit

/// Full-width message for the empty (ST-03) and error (ST-04) states:
/// icon, title, message and one action that reloads.
/// Neither state is in Figma, so it reuses the screen's tokens (D-05).
final class StateMessageView: UIView {

    var onAction: (() -> Void)?

    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(symbolName: String, message: StateMessage) {
        iconView.image = UIImage(systemName: symbolName,
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 28, weight: .semibold))
        titleLabel.text = message.title
        messageLabel.text = message.message

        var configuration = actionButton.configuration ?? .filled()
        configuration.attributedTitle = AttributedString(message.actionTitle, attributes: AttributeContainer([
            .font: Theme.Fonts.stateAction,
            .foregroundColor: Theme.Colors.onAccent
        ]))
        actionButton.configuration = configuration
    }

    // MARK: - Private

    private func setUpViews() {
        iconContainer.backgroundColor = Theme.Colors.onBackground.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 36
        iconContainer.isAccessibilityElement = false
        iconView.tintColor = Theme.Colors.accent
        iconView.contentMode = .center

        titleLabel.font = Theme.Fonts.stateTitle
        titleLabel.textColor = Theme.Colors.onBackground
        titleLabel.accessibilityTraits = .header

        messageLabel.font = Theme.Fonts.stateMessage
        messageLabel.textColor = Theme.Colors.onBackgroundSecondary

        [titleLabel, messageLabel].forEach {
            $0.textAlignment = .center
            $0.numberOfLines = 0
            $0.adjustsFontForContentSizeCategory = true
        }

        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = Theme.Colors.accent
        configuration.baseForegroundColor = Theme.Colors.onAccent
        configuration.background.cornerRadius = Theme.Radius.card
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 32, bottom: 12, trailing: 32)
        actionButton.configuration = configuration
        actionButton.addAction(UIAction { [weak self] _ in self?.onAction?() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconContainer, titleLabel, messageLabel, actionButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(20, after: iconContainer)
        stack.setCustomSpacing(28, after: messageLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.addSubview(iconView)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 72),
            iconContainer.heightAnchor.constraint(equalToConstant: 72),
            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),

            actionButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            actionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            stack.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
