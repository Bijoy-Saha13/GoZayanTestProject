//
//  FlightResultsCoordinator.swift
//  GoZayanProject
//

import SafariServices
import UIKit

/// Builds the Flight Results screen and handles its navigation. It implements the
/// ViewModel's delegate; the ViewModel never sees this type.
final class FlightResultsCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let dependencies: AppDependencies

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let viewModel = FlightResultsViewModel(request: dependencies.searchRequest,
                                               service: dependencies.flightSearchService,
                                               fareCalendar: dependencies.fareCalendar,
                                               promoProvider: dependencies.promoProvider)
        viewModel.delegate = self
        navigationController.setViewControllers([FlightResultsViewController(viewModel: viewModel)], animated: false)
    }
}

extension FlightResultsCoordinator: FlightResultsCoordinatorDelegate {

    func didSelectFlight(_ offer: FlightOffer) {
        // No flight details screen in scope (decision D-11).
    }

    /// FR-06: "Learn more" opens gozayaan.com in an in-app browser (decision D-13).
    func didSelectPromo(_ promo: Promo) {
        guard let scheme = promo.url.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return }
        navigationController.present(SFSafariViewController(url: promo.url), animated: true)
    }
}
