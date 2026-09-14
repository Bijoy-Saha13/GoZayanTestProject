//
//  Coordinator.swift
//  GoZayanProject
//

import UIKit

/// Owns navigation for one flow. The only layer allowed to push or present.
protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get }
    func start()
}

/// Root of the app. Retained by `SceneDelegate` for the life of the scene (spec ARCH-05).
final class AppCoordinator: Coordinator {

    let navigationController: UINavigationController
    private let dependencies: AppDependencies
    private var childCoordinators: [Coordinator] = []

    init(navigationController: UINavigationController, dependencies: AppDependencies) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }

    func start() {
        let flightResults = FlightResultsCoordinator(navigationController: navigationController,
                                                     dependencies: dependencies)
        childCoordinators.append(flightResults)
        flightResults.start()
    }
}
