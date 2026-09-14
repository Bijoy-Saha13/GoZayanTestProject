//
//  SkeletonCardCell.swift
//  GoZayanProject
//

import UIKit

/// Shimmering placeholder card shown while results load (FR-03).
final class SkeletonCardCell: UICollectionViewCell {

    static let height: CGFloat = 112

    private let cardView = UIView()
    private let shimmerView = ShimmerView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false

        cardView.backgroundColor = Theme.Colors.skeletonCard
        cardView.layer.cornerRadius = Theme.Radius.skeletonCard
        cardView.clipsToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)

        let avatar = makeBone(cornerRadius: 11)
        let titleBar = makeBone(cornerRadius: 4)
        let subtitleBar = makeBone(cornerRadius: 4)
        let pill = makeBone(cornerRadius: 4)
        [avatar, titleBar, subtitleBar, pill, shimmerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            avatar.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 16),
            avatar.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            avatar.widthAnchor.constraint(equalToConstant: 22),
            avatar.heightAnchor.constraint(equalToConstant: 22),

            titleBar.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 10),
            titleBar.topAnchor.constraint(equalTo: avatar.topAnchor),
            titleBar.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.58),
            titleBar.heightAnchor.constraint(equalToConstant: 8),

            subtitleBar.leadingAnchor.constraint(equalTo: titleBar.leadingAnchor),
            subtitleBar.topAnchor.constraint(equalTo: titleBar.bottomAnchor, constant: 6),
            subtitleBar.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.29),
            subtitleBar.heightAnchor.constraint(equalToConstant: 8),

            pill.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            pill.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24),
            pill.widthAnchor.constraint(equalToConstant: 48),
            pill.heightAnchor.constraint(equalToConstant: 16),

            shimmerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func makeBone(cornerRadius: CGFloat) -> UIView {
        let bone = UIView()
        bone.backgroundColor = Theme.Colors.skeletonBone
        bone.layer.cornerRadius = cornerRadius
        return bone
    }
}
