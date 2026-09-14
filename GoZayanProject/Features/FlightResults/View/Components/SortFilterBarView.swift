//
//  SortFilterBarView.swift
//  GoZayanProject
//

import UIKit

/// The "Cheapest ▾" sort dropdown button and the Filter button.
/// Filter is in the design but out of scope, so it is decorative.
final class SortFilterBarView: UIView {

    var onSortTap: (() -> Void)?

    /// Anchor for positioning the dropdown menu.
    let sortButton = UIButton(type: .system)
    private let filterButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        configure(sort: .cheapest, isMenuOpen: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(sort: SortOption, isMenuOpen: Bool) {
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString(sort.title, attributes: AttributeContainer([
            .font: Theme.Fonts.button,
            .foregroundColor: Theme.Colors.onBackground
        ]))
        configuration.image = UIImage(systemName: isMenuOpen ? "chevron.up" : "chevron.down",
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 8
        configuration.baseForegroundColor = Theme.Colors.onBackground
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        configuration.background.strokeColor = Theme.Colors.onBackground
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = Theme.Radius.button
        sortButton.configuration = configuration

        sortButton.accessibilityLabel = "Sort by \(sort.title)"
        sortButton.accessibilityValue = isMenuOpen ? "Expanded" : "Collapsed"
    }

    /// Sorting only makes sense when there are results. The design shows the button
    /// at full strength while loading, so dimming is a separate choice from disabling.
    func setSortEnabled(_ isEnabled: Bool, dimmed: Bool = false) {
        sortButton.isUserInteractionEnabled = isEnabled
        sortButton.alpha = dimmed ? 0.5 : 1
        sortButton.accessibilityTraits = isEnabled ? .button : [.button, .notEnabled]
    }

    // MARK: - Private

    private func setUpViews() {
        sortButton.addAction(UIAction { [weak self] _ in self?.onSortTap?() }, for: .touchUpInside)

        var filterConfiguration = UIButton.Configuration.filled()
        filterConfiguration.attributedTitle = AttributedString("Filter", attributes: AttributeContainer([
            .font: Theme.Fonts.button,
            .foregroundColor: Theme.Colors.onAccent
        ]))
        filterConfiguration.image = UIImage(systemName: "slider.horizontal.3",
                                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold))
        filterConfiguration.imagePlacement = .trailing
        filterConfiguration.imagePadding = 8
        filterConfiguration.baseForegroundColor = Theme.Colors.onAccent
        filterConfiguration.baseBackgroundColor = Theme.Colors.accent
        filterConfiguration.background.cornerRadius = Theme.Radius.button
        filterConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20)
        filterButton.configuration = filterConfiguration
        filterButton.accessibilityHint = "Filters aren't available."

        [sortButton, filterButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        let inset = Theme.Spacing.screenInset
        NSLayoutConstraint.activate([
            sortButton.topAnchor.constraint(equalTo: topAnchor),
            sortButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            sortButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            sortButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 97),
            sortButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 32),

            filterButton.topAnchor.constraint(equalTo: sortButton.topAnchor),
            filterButton.bottomAnchor.constraint(equalTo: sortButton.bottomAnchor),
            filterButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            filterButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 97),
            filterButton.leadingAnchor.constraint(greaterThanOrEqualTo: sortButton.trailingAnchor, constant: 12)
        ])
    }
}
