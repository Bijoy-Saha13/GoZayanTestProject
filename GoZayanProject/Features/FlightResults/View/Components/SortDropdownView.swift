//
//  SortDropdownView.swift
//  GoZayanProject
//

import UIKit

/// The sort menu from the Figma frame "Cheapest (Sorting Drop Down)":
/// a white card listing the options with the current one highlighted.
final class SortDropdownView: UIView {

    var onSelect: ((SortOption) -> Void)?

    private let stackView = UIStackView()

    init(options: [SortOption], selected: SortOption) {
        super.init(frame: .zero)
        setUpViews()
        options.forEach { stackView.addArrangedSubview(makeRow(for: $0, isSelected: $0 == selected)) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setUpViews() {
        backgroundColor = Theme.Colors.menuBackground
        layer.cornerRadius = Theme.Radius.card
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 4)
        accessibilityViewIsModal = true

        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    private func makeRow(for option: SortOption, isSelected: Bool) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(option.title, attributes: AttributeContainer([
            .font: Theme.Fonts.menuItem,
            .foregroundColor: isSelected ? Theme.Colors.price : Theme.Colors.textPrimary
        ]))
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)
        configuration.background.backgroundColor = isSelected ? Theme.Colors.menuSelectedBackground : .clear
        configuration.background.cornerRadius = Theme.Radius.button

        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        button.addAction(UIAction { [weak self] _ in self?.onSelect?(option) }, for: .touchUpInside)
        return button
    }
}
