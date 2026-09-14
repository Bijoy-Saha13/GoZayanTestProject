//
//  CachingHTTPClient.swift
//  GoZayanProject
//

import CryptoKit
import Foundation

/// Development cache for successful response bodies, so the ~100-search SerpApi
/// trial isn't used up while iterating (spec CACHE-01…04).
///
/// A decorator: the wrapped client knows nothing about caching. Only 2xx bodies are
/// stored, because the wrapped client throws for everything else. The cache key
/// ignores `api_key`, so the key never ends up in a file name.
nonisolated struct CachingHTTPClient: HTTPClient {

    private let wrapped: HTTPClient
    private let directory: URL
    private let maxAge: TimeInterval
    private let excludedQueryItems: Set<String>
    private let now: @Sendable () -> Date

    init(wrapping wrapped: HTTPClient,
         directory: URL = CachingHTTPClient.defaultDirectory,
         maxAge: TimeInterval = 24 * 60 * 60,
         excludedQueryItems: Set<String> = ["api_key"],
         now: @escaping @Sendable () -> Date = { Date() }) {
        self.wrapped = wrapped
        self.directory = directory
        self.maxAge = maxAge
        self.excludedQueryItems = excludedQueryItems
        self.now = now
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("HTTPResponseCache", isDirectory: true)
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        let fileURL = directory.appendingPathComponent(cacheKey(for: endpoint)).appendingPathExtension("json")

        if let cached = freshData(at: fileURL) {
            return cached
        }

        let data = try await wrapped.data(for: endpoint)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: fileURL, options: .atomic)
        return data
    }

    func cacheKey(for endpoint: Endpoint) -> String {
        let query = endpoint.queryItems
            .filter { !excludedQueryItems.contains($0.name) }
            .map { "\($0.name)=\($0.value ?? "")" }
            .sorted()
            .joined(separator: "&")
        let identity = "\(endpoint.method.rawValue) \(endpoint.host)\(endpoint.path)?\(query)"
        return SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private func freshData(at fileURL: URL) -> Data? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let modified = attributes[.modificationDate] as? Date,
              now().timeIntervalSince(modified) < maxAge else { return nil }
        return try? Data(contentsOf: fileURL)
    }
}
