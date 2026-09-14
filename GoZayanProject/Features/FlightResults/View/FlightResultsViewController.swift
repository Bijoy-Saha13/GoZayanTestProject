//
//  FlightResultsViewController.swift
//  GoZayanProject
//

import UIKit

/// Flight Results screen. Renders the ViewModel's `FlightResultsState` and forwards
/// user intents to it. It holds no business logic: it never calls the API, never
/// sorts, and never navigates.
final class FlightResultsViewController: UIViewController {

    private let viewModel: FlightResultsViewModel

    // MARK: - Collection view model

    nonisolated private enum Section: Hashable, Sendable {
        case loadingIntro
        case skeletonsTop
        case skeletonsBottom
        case offersTop
        case offersBottom
        case promos
    }

    nonisolated private enum Item: Hashable, Sendable {
        case loadingIntro
        case skeleton(Int)
        case offer(FlightCardViewData)
        case promo(PromoViewData)
    }

    private enum Layout {
        static let skeletonCountPerGroup = 2
    }

    // MARK: - Views

    private let headerView = RouteHeaderView()
    private let dateStripView = DateStripView()
    private let sortFilterBar = SortFilterBarView()
    private let stateMessageView = StateMessageView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private var dataSource: UICollectionViewDiffableDataSource<Section, Item>?

    private var sortMenuDismissControl: UIControl?
    private var sortMenu: SortDropdownView?

    // MARK: - Rendered values

    private var state: FlightResultsState = .loading
    private var dateChips: [DateChipViewData] = []
    private var promos: [PromoViewData] = []
    private var selectedSort: SortOption = .cheapest

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Lifecycle

    init(viewModel: FlightResultsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.Colors.background
        setUpViews()
        setUpConstraints()
        configureDataSource()

        headerView.configure(with: viewModel.header)
        dateChips = viewModel.dateChips
        promos = viewModel.promos
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.load()
    }

    // MARK: - Rendering

    private func render(_ state: FlightResultsState) {
        let isSameKind = state.kind == self.state.kind
        let sortChanged = state.selectedSort != nil && state.selectedSort != self.state.selectedSort
        self.state = state
        applyState(animated: isSameKind)
        if sortChanged {
            collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.adjustedContentInset.top), animated: true)
        }
    }

    private func applyState(animated: Bool) {
        guard isViewLoaded else { return }

        if case .success(let content) = state {
            selectedSort = content.selectedSort
        } else {
            dismissSortMenu()
        }

        dateStripView.configure(chips: dateChips, isLoading: state == .loading)
        sortFilterBar.configure(sort: selectedSort, isMenuOpen: sortMenu != nil)

        switch state {
        case .loading:
            sortFilterBar.setSortEnabled(false)
            showList()
        case .success:
            sortFilterBar.setSortEnabled(true)
            showList()
        case .empty:
            sortFilterBar.setSortEnabled(false, dimmed: true)
            showMessage(symbolName: "airplane.circle", message: .noFlights)
        case .error(let error):
            sortFilterBar.setSortEnabled(false, dimmed: true)
            showMessage(symbolName: error.symbolName, message: error.stateMessage)
        }

        dataSource?.apply(makeSnapshot(), animatingDifferences: animated)
        if !animated {
            collectionView.setContentOffset(CGPoint(x: 0, y: -collectionView.adjustedContentInset.top), animated: false)
        }
    }

    private func showList() {
        collectionView.isHidden = false
        stateMessageView.isHidden = true
    }

    private func showMessage(symbolName: String, message: StateMessage) {
        stateMessageView.configure(symbolName: symbolName, message: message)
        stateMessageView.isHidden = false
        collectionView.isHidden = true
        UIAccessibility.post(notification: .screenChanged, argument: stateMessageView)
    }

    private func makeSnapshot() -> NSDiffableDataSourceSnapshot<Section, Item> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()
        let promoItems = promos.map(Item.promo)

        switch state {
        case .loading:
            let skeletons = (0..<Layout.skeletonCountPerGroup * 2).map(Item.skeleton)
            snapshot.appendSections([.loadingIntro, .skeletonsTop])
            snapshot.appendItems([.loadingIntro], toSection: .loadingIntro)
            snapshot.appendItems(Array(skeletons.prefix(Layout.skeletonCountPerGroup)), toSection: .skeletonsTop)
            if !promoItems.isEmpty {
                snapshot.appendSections([.promos])
                snapshot.appendItems(promoItems, toSection: .promos)
            }
            snapshot.appendSections([.skeletonsBottom])
            snapshot.appendItems(Array(skeletons.suffix(Layout.skeletonCountPerGroup)), toSection: .skeletonsBottom)

        case .success(let content):
            let offers = content.offers.map(Item.offer)
            let splitIndex = min(max(content.promoInsertionIndex, 0), offers.count)
            snapshot.appendSections([.offersTop])
            snapshot.appendItems(Array(offers[..<splitIndex]), toSection: .offersTop)
            if !promoItems.isEmpty {
                snapshot.appendSections([.promos])
                snapshot.appendItems(promoItems, toSection: .promos)
            }
            if splitIndex < offers.count {
                snapshot.appendSections([.offersBottom])
                snapshot.appendItems(Array(offers[splitIndex...]), toSection: .offersBottom)
            }

        case .empty, .error:
            break
        }
        return snapshot
    }

    // MARK: - Sort menu

    private func toggleSortMenu() {
        sortMenu == nil ? presentSortMenu() : dismissSortMenu()
    }

    private func presentSortMenu() {
        guard case .success = state, sortMenu == nil else { return }

        let dismissControl = UIControl()
        dismissControl.accessibilityLabel = "Close sort menu"
        dismissControl.addAction(UIAction { [weak self] _ in self?.dismissSortMenu() }, for: .touchUpInside)

        let menu = SortDropdownView(options: SortOption.allCases, selected: selectedSort)
        menu.onSelect = { [weak self] option in
            self?.dismissSortMenu()
            self?.viewModel.selectSort(option)
        }

        [dismissControl, menu].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            dismissControl.topAnchor.constraint(equalTo: view.topAnchor),
            dismissControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dismissControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dismissControl.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            menu.topAnchor.constraint(equalTo: sortFilterBar.sortButton.bottomAnchor, constant: 6),
            menu.leadingAnchor.constraint(equalTo: sortFilterBar.sortButton.leadingAnchor),
            menu.widthAnchor.constraint(equalToConstant: 156)
        ])

        sortMenuDismissControl = dismissControl
        sortMenu = menu
        sortFilterBar.configure(sort: selectedSort, isMenuOpen: true)

        menu.alpha = 0
        menu.transform = CGAffineTransform(translationX: 0, y: -6)
        UIView.animate(withDuration: 0.18) {
            menu.alpha = 1
            menu.transform = .identity
        }
        UIAccessibility.post(notification: .screenChanged, argument: menu)
    }

    private func dismissSortMenu() {
        guard let menu = sortMenu else { return }
        sortMenuDismissControl?.removeFromSuperview()
        menu.removeFromSuperview()
        sortMenuDismissControl = nil
        sortMenu = nil
        sortFilterBar.configure(sort: selectedSort, isMenuOpen: false)
        UIAccessibility.post(notification: .layoutChanged, argument: sortFilterBar.sortButton)
    }

    // MARK: - Setup

    private func setUpViews() {
        sortFilterBar.onSortTap = { [weak self] in self?.toggleSortMenu() }
        stateMessageView.onAction = { [weak self] in self?.viewModel.retry() }

        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.alwaysBounceVertical = true

        [headerView, dateStripView, sortFilterBar, collectionView, stateMessageView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
    }

    private func setUpConstraints() {
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            dateStripView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            dateStripView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dateStripView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            sortFilterBar.topAnchor.constraint(equalTo: dateStripView.bottomAnchor, constant: 16),
            sortFilterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sortFilterBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: sortFilterBar.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stateMessageView.topAnchor.constraint(equalTo: sortFilterBar.bottomAnchor, constant: 16),
            stateMessageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stateMessageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            stateMessageView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -48)
        ])
    }

    private func configureDataSource() {
        let introRegistration = UICollectionView.CellRegistration<SearchProgressCell, Item> { _, _, _ in }
        let skeletonRegistration = UICollectionView.CellRegistration<SkeletonCardCell, Item> { _, _, _ in }
        let offerRegistration = UICollectionView.CellRegistration<FlightCardCell, FlightCardViewData> { cell, _, offer in
            cell.configure(with: offer)
        }
        let promoRegistration = UICollectionView.CellRegistration<PromoCardCell, PromoViewData> { [weak self] cell, _, promo in
            cell.configure(with: promo)
            cell.onLearnMore = { self?.viewModel.didTapLearnMore(promoID: promo.id) }
        }

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            switch item {
            case .loadingIntro:
                collectionView.dequeueConfiguredReusableCell(using: introRegistration, for: indexPath, item: item)
            case .skeleton:
                collectionView.dequeueConfiguredReusableCell(using: skeletonRegistration, for: indexPath, item: item)
            case .offer(let offer):
                collectionView.dequeueConfiguredReusableCell(using: offerRegistration, for: indexPath, item: offer)
            case .promo(let promo):
                collectionView.dequeueConfiguredReusableCell(using: promoRegistration, for: indexPath, item: promo)
            }
        }
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let section = self?.dataSource?.sectionIdentifier(for: sectionIndex) else { return nil }
            let inset = Theme.Spacing.screenInset

            switch section {
            case .loadingIntro:
                return Self.listSection(height: .estimated(120), spacing: 0,
                                        insets: NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 12, trailing: inset))
            case .skeletonsTop, .skeletonsBottom:
                return Self.listSection(height: .absolute(SkeletonCardCell.height), spacing: 8,
                                        insets: NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 12, trailing: inset))
            case .offersTop, .offersBottom:
                return Self.listSection(height: .estimated(180), spacing: Theme.Spacing.cardSpacing,
                                        insets: NSDirectionalEdgeInsets(top: 0, leading: inset, bottom: 16, trailing: inset))
            case .promos:
                return Self.promoSection()
            }
        }
    }

    private static func listSection(height: NSCollectionLayoutDimension, spacing: CGFloat,
                                     insets: NSDirectionalEdgeInsets) -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: height)
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = spacing
        section.contentInsets = insets
        return section
    }

    /// Sideways-scrolling carousel between the flight cards (FR-05).
    private static func promoSection() -> NSCollectionLayoutSection {
        let size = NSCollectionLayoutSize(widthDimension: .absolute(PromoCardCell.size.width),
                                          heightDimension: .absolute(PromoCardCell.size.height))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 16, trailing: 0)
        return section
    }
}

// MARK: - UICollectionViewDelegate

extension FlightResultsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if case .offer = dataSource?.itemIdentifier(for: indexPath) { return true }
        return false
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard case .offer(let offer) = dataSource?.itemIdentifier(for: indexPath) else { return }
        viewModel.didSelectOffer(id: offer.id)
    }
}

// MARK: - Helpers

private extension FlightResultsState {
    enum Kind { case loading, success, empty, error }

    var kind: Kind {
        switch self {
        case .loading: .loading
        case .success: .success
        case .empty: .empty
        case .error: .error
        }
    }

    var selectedSort: SortOption? {
        if case .success(let content) = self { content.selectedSort } else { nil }
    }
}

private extension FlightResultsError {
    var symbolName: String {
        switch self {
        case .offline: "wifi.slash"
        case .unauthorized: "lock.circle"
        case .quotaExceeded: "hourglass"
        case .server, .invalidResponse: "exclamationmark.triangle"
        }
    }
}
