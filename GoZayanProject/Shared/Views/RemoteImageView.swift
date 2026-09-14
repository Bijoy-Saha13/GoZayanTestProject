//
//  RemoteImageView.swift
//  GoZayanProject
//

import UIKit

/// Image view that loads a remote image (airline logos from SerpApi) with an
/// in-memory cache. Safe for reuse in cells: a late response for a previous
/// URL is ignored.
final class RemoteImageView: UIImageView {

    private var loadTask: Task<Void, Never>?
    private var currentURL: URL?

    func setImage(from url: URL?, placeholder: UIImage?) {
        cancelLoading()
        currentURL = url
        image = placeholder
        guard let url else { return }

        if let cached = ImageCache.shared.image(for: url) {
            image = cached
            return
        }

        loadTask = Task { [weak self] in
            guard let result = try? await URLSession.shared.data(for: URLRequest(url: url)),
                  let downloaded = UIImage(data: result.0) else { return }
            ImageCache.shared.insert(downloaded, for: url)
            guard !Task.isCancelled, let self, self.currentURL == url else { return }
            self.image = downloaded
        }
    }

    func cancelLoading() {
        loadTask?.cancel()
        loadTask = nil
        currentURL = nil
    }
}

final class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
