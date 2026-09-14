//
//  FlightCardCell.swift
//  GoZayanProject
//

import UIKit

/// Flight card (FR-04): airline, departure/arrival time, duration, stops,
/// both airport codes and the starting price.
final class FlightCardCell: UICollectionViewCell {

    private let cardView = UIView()

    private let logoView = RemoteImageView()
    private let airlineLabel = UILabel()
    private let pointsIcon = UIImageView()
    private let pointsLabel = UILabel()

    private let departureTimeLabel = UILabel()
    private let departureCodeLabel = UILabel()
    private let arrivalTimeLabel = UILabel()
    private let arrivalCodeLabel = UILabel()
    private let durationLabel = UILabel()
    private let routeLineView = RouteLineView()
    private let stopsLabel = UILabel()

    private let separator = DashedLineView(color: Theme.Colors.dashedSeparator)
    private let startingFromLabel = UILabel()
    private let priceLabel = UILabel()

    private static let logoPlaceholder = UIImage(systemName: "airplane.circle.fill")?
        .withTintColor(Theme.Colors.route, renderingMode: .alwaysOriginal)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
        setUpConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var isHighlighted: Bool {
        didSet { cardView.alpha = isHighlighted ? 0.85 : 1 }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        logoView.cancelLoading()
    }

    func configure(with data: FlightCardViewData) {
        logoView.setImage(from: data.airlineLogoURL, placeholder: Self.logoPlaceholder)
        airlineLabel.text = data.airlineName

        departureTimeLabel.text = data.departureTime
        departureCodeLabel.text = data.departureCode
        arrivalTimeLabel.attributedText = makeArrivalTime(time: data.arrivalTime, dayOffset: data.dayOffsetText)
        arrivalCodeLabel.text = data.arrivalCode

        durationLabel.text = data.durationText
        routeLineView.stopCount = data.stopCount
        stopsLabel.text = data.stopsText

        priceLabel.attributedText = makePrice(data.price)
        startingFromLabel.isHidden = data.price == nil
        accessibilityLabel = data.accessibilityLabel
    }

    // MARK: - Private

    private func setUpViews() {
        isAccessibilityElement = true
        accessibilityTraits = .button

        cardView.backgroundColor = Theme.Colors.card
        cardView.layer.cornerRadius = Theme.Radius.card

        logoView.contentMode = .scaleAspectFit
        logoView.layer.cornerRadius = 4
        logoView.clipsToBounds = true

        style(airlineLabel, font: Theme.Fonts.airline, color: Theme.Colors.textPrimary)
        airlineLabel.lineBreakMode = .byTruncatingTail
        airlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        pointsIcon.image = UIImage(systemName: "star.circle.fill")
        pointsIcon.tintColor = Theme.Colors.points
        pointsIcon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(font: Theme.Fonts.points)
        style(pointsLabel, font: Theme.Fonts.points, color: Theme.Colors.textSecondary)
        pointsLabel.text = "Get Points"
        [pointsIcon, pointsLabel].forEach {
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
            $0.setContentHuggingPriority(.required, for: .horizontal)
        }

        style(departureTimeLabel, font: Theme.Fonts.time, color: Theme.Colors.textPrimary)
        style(departureCodeLabel, font: Theme.Fonts.airportCode, color: Theme.Colors.textSecondary)
        style(arrivalTimeLabel, font: Theme.Fonts.time, color: Theme.Colors.textPrimary)
        style(arrivalCodeLabel, font: Theme.Fonts.airportCode, color: Theme.Colors.textSecondary)
        arrivalTimeLabel.textAlignment = .right
        arrivalCodeLabel.textAlignment = .right

        style(durationLabel, font: Theme.Fonts.duration, color: Theme.Colors.textSecondary)
        style(stopsLabel, font: Theme.Fonts.stops, color: Theme.Colors.textSecondary)
        durationLabel.textAlignment = .center
        stopsLabel.textAlignment = .center

        style(startingFromLabel, font: Theme.Fonts.startingFrom, color: Theme.Colors.textSecondary)
        startingFromLabel.text = "Starting from"
        startingFromLabel.textAlignment = .right
        priceLabel.textAlignment = .right
        priceLabel.adjustsFontForContentSizeCategory = true

        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        [logoView, airlineLabel, pointsIcon, pointsLabel,
         departureTimeLabel, departureCodeLabel, arrivalTimeLabel, arrivalCodeLabel,
         durationLabel, routeLineView, stopsLabel,
         separator, startingFromLabel, priceLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            cardView.addSubview($0)
        }
    }

    private func setUpConstraints() {
        let padding = Theme.Spacing.cardPadding

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            // Airline row
            logoView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: padding),
            logoView.centerYAnchor.constraint(equalTo: airlineLabel.centerYAnchor),
            logoView.widthAnchor.constraint(equalToConstant: 20),
            logoView.heightAnchor.constraint(equalToConstant: 20),

            airlineLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: padding),
            airlineLabel.leadingAnchor.constraint(equalTo: logoView.trailingAnchor, constant: 8),
            airlineLabel.trailingAnchor.constraint(lessThanOrEqualTo: pointsIcon.leadingAnchor, constant: -8),

            pointsLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -padding),
            pointsLabel.centerYAnchor.constraint(equalTo: airlineLabel.centerYAnchor),
            pointsIcon.trailingAnchor.constraint(equalTo: pointsLabel.leadingAnchor, constant: -4),
            pointsIcon.centerYAnchor.constraint(equalTo: pointsLabel.centerYAnchor),

            // Route column, centred on the card
            durationLabel.topAnchor.constraint(equalTo: airlineLabel.bottomAnchor, constant: 18),
            durationLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            routeLineView.topAnchor.constraint(equalTo: durationLabel.bottomAnchor, constant: 4),
            routeLineView.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            routeLineView.widthAnchor.constraint(equalToConstant: 96),
            stopsLabel.topAnchor.constraint(equalTo: routeLineView.bottomAnchor, constant: 4),
            stopsLabel.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),

            // Departure column
            departureTimeLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: padding),
            departureTimeLabel.centerYAnchor.constraint(equalTo: routeLineView.centerYAnchor, constant: -8),
            departureTimeLabel.trailingAnchor.constraint(lessThanOrEqualTo: routeLineView.leadingAnchor, constant: -8),
            departureCodeLabel.topAnchor.constraint(equalTo: departureTimeLabel.bottomAnchor, constant: 2),
            departureCodeLabel.leadingAnchor.constraint(equalTo: departureTimeLabel.leadingAnchor),

            // Arrival column
            arrivalTimeLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -padding),
            arrivalTimeLabel.firstBaselineAnchor.constraint(equalTo: departureTimeLabel.firstBaselineAnchor),
            arrivalTimeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: routeLineView.trailingAnchor, constant: 8),
            arrivalCodeLabel.topAnchor.constraint(equalTo: arrivalTimeLabel.bottomAnchor, constant: 2),
            arrivalCodeLabel.trailingAnchor.constraint(equalTo: arrivalTimeLabel.trailingAnchor),

            // Separator below whichever column is tallest
            separator.topAnchor.constraint(greaterThanOrEqualTo: stopsLabel.bottomAnchor, constant: 12),
            separator.topAnchor.constraint(greaterThanOrEqualTo: departureCodeLabel.bottomAnchor, constant: 12),
            separator.topAnchor.constraint(greaterThanOrEqualTo: arrivalCodeLabel.bottomAnchor, constant: 12),
            separator.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: padding),
            separator.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -padding),
            separator.heightAnchor.constraint(equalToConstant: 1),

            // Price
            startingFromLabel.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 12),
            startingFromLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -padding),
            startingFromLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: padding),
            priceLabel.topAnchor.constraint(equalTo: startingFromLabel.bottomAnchor, constant: 2),
            priceLabel.trailingAnchor.constraint(equalTo: startingFromLabel.trailingAnchor),
            priceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: cardView.leadingAnchor, constant: padding),
            priceLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -padding)
        ])

        // Keep the separator tight under the tallest column instead of floating.
        let tightSeparator = separator.topAnchor.constraint(equalTo: stopsLabel.bottomAnchor, constant: 12)
        tightSeparator.priority = .defaultLow
        tightSeparator.isActive = true
    }

    private func style(_ label: UILabel, font: UIFont, color: UIColor) {
        label.font = font
        label.textColor = color
        label.adjustsFontForContentSizeCategory = true
    }

    /// "08:20" followed by a raised, red "+1Day".
    private func makeArrivalTime(time: String, dayOffset: String?) -> NSAttributedString {
        let text = NSMutableAttributedString(string: time, attributes: [
            .font: Theme.Fonts.time,
            .foregroundColor: Theme.Colors.textPrimary
        ])
        if let dayOffset {
            text.append(NSAttributedString(string: dayOffset, attributes: [
                .font: Theme.Fonts.dayOffset,
                .foregroundColor: Theme.Colors.dayOffset,
                .baselineOffset: Theme.Fonts.time.capHeight - Theme.Fonts.dayOffset.capHeight
            ]))
        }
        return text
    }

    /// "BDT 37,400" with a small grey currency code and a bold amount,
    /// or "Price unavailable" when the API omitted the price (D-07).
    private func makePrice(_ price: FlightCardViewData.Price?) -> NSAttributedString {
        guard let price else {
            return NSAttributedString(string: "Price unavailable", attributes: [
                .font: Theme.Fonts.currency,
                .foregroundColor: Theme.Colors.textSecondary
            ])
        }
        let text = NSMutableAttributedString(string: price.currencyCode + " ", attributes: [
            .font: Theme.Fonts.currency,
            .foregroundColor: Theme.Colors.textSecondary
        ])
        text.append(NSAttributedString(string: price.amountText, attributes: [
            .font: Theme.Fonts.priceAmount,
            .foregroundColor: Theme.Colors.price
        ]))
        return text
    }
}
