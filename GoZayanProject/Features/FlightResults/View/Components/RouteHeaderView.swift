//
//  RouteHeaderView.swift
//  GoZayanProject
//

import UIKit

/// Route header (FR-01): route, date, passenger count, "One Way", and an Edit button.
///
/// The back chevron is in the design but decorative — Flight Results is the app's
/// root, so there is nowhere to go back to. Edit is decorative as the brief allows.
final class RouteHeaderView: UIView {

    private let backButton = UIButton(type: .system)
    private let editButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let textStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with data: RouteHeaderViewData) {
        titleLabel.text = data.title
        subtitleLabel.attributedText = makeSubtitle(for: data)
        textStack.accessibilityLabel = data.accessibilityLabel
    }

    // MARK: - Private

    private func setUpViews() {
        var backConfiguration = UIButton.Configuration.plain()
        backConfiguration.image = UIImage(systemName: "chevron.left",
                                          withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .medium))
        backConfiguration.baseForegroundColor = Theme.Colors.onBackground
        backConfiguration.contentInsets = .zero
        backButton.configuration = backConfiguration
        backButton.isUserInteractionEnabled = false
        backButton.isAccessibilityElement = false

        var editConfiguration = UIButton.Configuration.plain()
        editConfiguration.attributedTitle = AttributedString("Edit", attributes: AttributeContainer([
            .font: Theme.Fonts.headerAction,
            .foregroundColor: Theme.Colors.onBackground
        ]))
        editConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 0)
        editButton.configuration = editConfiguration
        editButton.accessibilityHint = "Editing the search isn't available."

        titleLabel.font = Theme.Fonts.headerTitle
        titleLabel.textColor = Theme.Colors.onBackground
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.lineBreakMode = .byTruncatingTail

        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.adjustsFontForContentSizeCategory = true

        textStack.axis = .vertical
        textStack.alignment = .center
        textStack.spacing = 4
        textStack.isAccessibilityElement = true
        textStack.accessibilityTraits = .header
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(subtitleLabel)

        [backButton, textStack, editButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
    }

    private func setUpConstraints() {
        let inset = Theme.Spacing.screenInset
        backButton.setContentHuggingPriority(.required, for: .horizontal)
        editButton.setContentHuggingPriority(.required, for: .horizontal)
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            textStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            textStack.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -8),

            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            backButton.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 24),

            editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            editButton.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),
            editButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44),
            editButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    /// "14 Oct, 2026  |  👤01  |  One Way"
    private func makeSubtitle(for data: RouteHeaderViewData) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Theme.Fonts.headerSubtitle,
            .foregroundColor: Theme.Colors.onBackground
        ]
        let separator = "  |  "
        let text = NSMutableAttributedString(string: data.dateText + separator, attributes: attributes)

        let symbolConfiguration = UIImage.SymbolConfiguration(font: Theme.Fonts.headerSubtitle, scale: .small)
        if let person = UIImage(systemName: "person", withConfiguration: symbolConfiguration)?
            .withTintColor(Theme.Colors.onBackground, renderingMode: .alwaysOriginal) {
            text.append(NSAttributedString(attachment: NSTextAttachment(image: person)))
        }

        text.append(NSAttributedString(string: data.passengerCountText + separator + data.tripTypeText,
                                       attributes: attributes))
        return text
    }
}
