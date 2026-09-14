//
//  PromoCardCell.swift
//  GoZayanProject
//

import UIKit

/// One card in the discount carousel (FR-05): image, title and a "Learn more" link.
/// The cell only reports the tap; opening the link is the Coordinator's job (FR-06).
final class PromoCardCell: UICollectionViewCell {

    static let size = CGSize(width: 212, height: 52)

    var onLearnMore: (() -> Void)?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let learnMoreButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onLearnMore = nil
    }

    func configure(with promo: PromoViewData) {
        imageView.image = UIImage(named: promo.imageName)
        titleLabel.text = promo.title
        titleLabel.accessibilityLabel = "Offer: \(promo.title)"
        learnMoreButton.accessibilityLabel = "Learn more about \(promo.title)"
    }

    // MARK: - Private

    private func setUpViews() {
        contentView.backgroundColor = Theme.Colors.promoBackground
        contentView.layer.cornerRadius = Theme.Radius.promo
        contentView.layer.borderColor = Theme.Colors.promoBorder.cgColor
        contentView.layer.borderWidth = 1
        contentView.clipsToBounds = true

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = Theme.Colors.background
        imageView.isAccessibilityElement = false

        titleLabel.font = Theme.Fonts.promoTitle
        titleLabel.textColor = Theme.Colors.textPrimary
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85

        var configuration = UIButton.Configuration.plain()
        var title = AttributedString("Learn more")
        title.font = Theme.Fonts.promoLink
        title.foregroundColor = Theme.Colors.textSecondary
        title.underlineStyle = .single
        configuration.attributedTitle = title
        configuration.image = UIImage(systemName: "arrow.up.right",
                                      withConfiguration: UIImage.SymbolConfiguration(pointSize: 8, weight: .semibold))
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.baseForegroundColor = Theme.Colors.textSecondary
        configuration.contentInsets = .zero
        learnMoreButton.configuration = configuration
        learnMoreButton.accessibilityTraits = .link
        learnMoreButton.addAction(UIAction { [weak self] _ in self?.onLearnMore?() }, for: .touchUpInside)

        [imageView, titleLabel, learnMoreButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 64),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),

            learnMoreButton.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor),
            learnMoreButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            learnMoreButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
}
