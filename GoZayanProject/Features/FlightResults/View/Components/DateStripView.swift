//
//  DateStripView.swift
//  GoZayanProject
//

import UIKit

/// Date & price strip (FR-02): horizontally scrolling day chips with a fare under
/// each and the selected day highlighted. Taps are ignored by design — selection
/// is disabled on the collection view, so nothing can change on tap.
///
/// While loading, fares are replaced by shimmering bones and the price-trend
/// badge turns white, as in the Figma loading frame.
final class DateStripView: UIView {

    private enum Layout {
        static let chipSize = CGSize(width: 104, height: 58)
        static let badgeSize: CGFloat = 40
    }

    private var chips: [DateChipViewData] = []
    private var isLoading = false
    private var needsScrollToSelection = false

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = Layout.chipSize
        layout.minimumLineSpacing = 0
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = false
        collectionView.dataSource = self
        collectionView.register(DateChipCell.self, forCellWithReuseIdentifier: DateChipCell.reuseIdentifier)
        return collectionView
    }()

    private let trendBadge = UIView()
    private let trendIcon = UIImageView()
    private let divider = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(chips: [DateChipViewData], isLoading: Bool) {
        let chipsChanged = chips != self.chips
        self.chips = chips
        self.isLoading = isLoading

        let tint = isLoading ? Theme.Colors.onBackground : Theme.Colors.accent
        trendBadge.layer.borderColor = tint.cgColor
        trendIcon.tintColor = tint

        collectionView.reloadData()
        if chipsChanged {
            needsScrollToSelection = true
            setNeedsLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollToSelectionIfNeeded()
    }

    // MARK: - Private

    /// FR-02a: bring the highlighted day into view on first display.
    private func scrollToSelectionIfNeeded() {
        guard needsScrollToSelection, collectionView.bounds.width > 0,
              let index = chips.firstIndex(where: \.isSelected) else { return }
        needsScrollToSelection = false
        collectionView.layoutIfNeeded()
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0),
                                    at: .centeredHorizontally, animated: false)
    }

    private func setUpViews() {
        trendBadge.layer.cornerRadius = Theme.Radius.button
        trendBadge.layer.borderWidth = 1
        trendBadge.isAccessibilityElement = false
        trendIcon.image = UIImage(systemName: "chart.line.uptrend.xyaxis",
                                  withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .regular))
        trendIcon.contentMode = .center

        divider.backgroundColor = Theme.Colors.divider

        [collectionView, trendBadge, divider].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        trendIcon.translatesAutoresizingMaskIntoConstraints = false
        trendBadge.addSubview(trendIcon)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trendBadge.leadingAnchor, constant: -8),
            collectionView.heightAnchor.constraint(equalToConstant: Layout.chipSize.height),

            trendBadge.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.screenInset),
            trendBadge.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor, constant: -3),
            trendBadge.widthAnchor.constraint(equalToConstant: Layout.badgeSize),
            trendBadge.heightAnchor.constraint(equalToConstant: Layout.badgeSize),

            trendIcon.centerXAnchor.constraint(equalTo: trendBadge.centerXAnchor),
            trendIcon.centerYAnchor.constraint(equalTo: trendBadge.centerYAnchor),

            divider.topAnchor.constraint(equalTo: collectionView.bottomAnchor),
            divider.leadingAnchor.constraint(equalTo: leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: trailingAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1),
            divider.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

extension DateStripView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        chips.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DateChipCell.reuseIdentifier,
                                                      for: indexPath) as! DateChipCell
        cell.configure(with: chips[indexPath.item], isLoading: isLoading)
        return cell
    }
}

// MARK: - DateChipCell

final class DateChipCell: UICollectionViewCell {
    static let reuseIdentifier = "DateChipCell"

    private let dayLabel = UILabel()
    private let fareLabel = UILabel()
    private let fareBone = UIView()
    private let fareShimmer = ShimmerView()
    private let selectionIndicator = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true

        dayLabel.font = Theme.Fonts.chipDay
        fareLabel.font = Theme.Fonts.chipFare
        [dayLabel, fareLabel].forEach { $0.textAlignment = .center }

        fareBone.backgroundColor = Theme.Colors.skeletonBone
        fareBone.layer.cornerRadius = 5
        fareBone.clipsToBounds = true
        selectionIndicator.backgroundColor = Theme.Colors.accent

        [dayLabel, fareLabel, fareBone, selectionIndicator].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        fareShimmer.translatesAutoresizingMaskIntoConstraints = false
        fareBone.addSubview(fareShimmer)

        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            dayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),

            fareLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 4),
            fareLabel.leadingAnchor.constraint(equalTo: dayLabel.leadingAnchor),
            fareLabel.trailingAnchor.constraint(equalTo: dayLabel.trailingAnchor),

            fareBone.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            fareBone.centerYAnchor.constraint(equalTo: fareLabel.centerYAnchor),
            fareBone.widthAnchor.constraint(equalToConstant: 72),
            fareBone.heightAnchor.constraint(equalToConstant: 10),

            fareShimmer.topAnchor.constraint(equalTo: fareBone.topAnchor),
            fareShimmer.leadingAnchor.constraint(equalTo: fareBone.leadingAnchor),
            fareShimmer.trailingAnchor.constraint(equalTo: fareBone.trailingAnchor),
            fareShimmer.bottomAnchor.constraint(equalTo: fareBone.bottomAnchor),

            selectionIndicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionIndicator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            selectionIndicator.heightAnchor.constraint(equalToConstant: 3)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with chip: DateChipViewData, isLoading: Bool) {
        let isHighlighted = chip.isSelected && !isLoading
        let color = isHighlighted ? Theme.Colors.accent : Theme.Colors.onBackground

        dayLabel.text = chip.dayText
        dayLabel.textColor = color
        fareLabel.text = chip.fareText
        fareLabel.textColor = color
        fareLabel.isHidden = isLoading
        fareBone.isHidden = !isLoading
        selectionIndicator.isHidden = !isHighlighted

        accessibilityLabel = isLoading ? "\(chip.dayText), fare loading" : "\(chip.dayText), \(chip.fareText)"
        accessibilityTraits = isHighlighted ? [.staticText, .selected] : .staticText
    }
}
