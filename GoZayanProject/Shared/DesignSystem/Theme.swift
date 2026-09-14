//
//  Theme.swift
//  GoZayanProject
//
//  Design tokens for the Flight Results screen, taken from the Figma frames
//  "Flight Result - After Search, One Way" and "Cheapest (Sorting Drop Down)".
//  Colours are matched by eye from the public Figma view (inspect needs a
//  Figma account), so every value lives here and nowhere else.
//

import UIKit

enum Theme {

    enum Colors {
        // Screen
        static let background = UIColor(hex: 0x0A0B80)
        static let onBackground = UIColor.white
        static let onBackgroundSecondary = UIColor(white: 1, alpha: 0.8)
        static let divider = UIColor(white: 1, alpha: 0.28)

        // Accent (selected date, Filter button, primary actions)
        static let accent = UIColor(hex: 0xF7C948)
        static let onAccent = UIColor(hex: 0x0A0B6E)

        // Loading
        static let progressTrack = UIColor.white
        static let progressFill = UIColor(hex: 0xF26B3A)
        static let skeletonCard = UIColor(hex: 0x24359F)
        static let skeletonBone = UIColor(hex: 0x4F68CF)
        static let shimmerHighlight = UIColor(white: 1, alpha: 0.22)

        // Flight card
        static let card = UIColor.white
        static let textPrimary = UIColor(hex: 0x172033)
        static let textSecondary = UIColor(hex: 0x5B6475)
        static let price = UIColor(hex: 0x0A0B6E)
        static let route = UIColor(hex: 0x4A6BC6)
        static let dayOffset = UIColor(hex: 0xE5484D)
        static let dashedSeparator = UIColor(hex: 0xD3D8E0)
        static let points = UIColor(hex: 0xF4B400)

        // Promo carousel
        static let promoBackground = UIColor(hex: 0xE9FBF0)
        static let promoBorder = UIColor.white

        // Sort dropdown
        static let menuBackground = UIColor.white
        static let menuSelectedBackground = UIColor(hex: 0xEDF0FA)
    }

    enum Spacing {
        static let screenInset: CGFloat = 16
        static let cardPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 12
    }

    enum Radius {
        static let card: CGFloat = 8
        static let skeletonCard: CGFloat = 14
        static let button: CGFloat = 6
        static let promo: CGFloat = 8
    }

    /// The design uses a geometric sans that isn't bundled; SF Pro at the same
    /// sizes/weights is the stand-in. Fonts scale with Dynamic Type up to a cap
    /// so the fixed-height parts of the layout (date strip, carousel) stay usable.
    enum Fonts {
        static let headerTitle = scaled(20, .bold, style: .title3)
        static let headerSubtitle = scaled(13, .regular, style: .subheadline)
        static let headerAction = scaled(14, .semibold, style: .subheadline)

        static let chipDay = fixed(13, .regular)
        static let chipFare = fixed(15, .semibold)

        static let button = scaled(14, .semibold, style: .subheadline)

        static let loadingMessage = scaled(20, .semibold, style: .title3)

        static let airline = scaled(15, .regular, style: .subheadline)
        static let points = scaled(13, .regular, style: .footnote)
        static let time = scaled(20, .bold, style: .title3)
        static let dayOffset = scaled(11, .semibold, style: .caption2)
        static let airportCode = scaled(14, .regular, style: .subheadline)
        static let duration = scaled(12, .regular, style: .caption1)
        static let stops = scaled(13, .regular, style: .footnote)
        static let startingFrom = scaled(13, .regular, style: .footnote)
        static let currency = scaled(14, .regular, style: .subheadline)
        static let priceAmount = scaled(20, .bold, style: .title3)

        static let promoTitle = fixed(13, .semibold)
        static let promoLink = fixed(11, .regular)

        static let menuItem = scaled(14, .semibold, style: .subheadline)

        static let stateTitle = scaled(20, .semibold, style: .title3)
        static let stateMessage = scaled(15, .regular, style: .body)
        static let stateAction = scaled(15, .semibold, style: .body)

        private static func scaled(_ size: CGFloat, _ weight: UIFont.Weight, style: UIFont.TextStyle) -> UIFont {
            UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: size, weight: weight),
                                                          maximumPointSize: size * 1.5)
        }

        private static func fixed(_ size: CGFloat, _ weight: UIFont.Weight) -> UIFont {
            .systemFont(ofSize: size, weight: weight)
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
