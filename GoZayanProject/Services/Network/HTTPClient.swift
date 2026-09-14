//
//  HTTPClient.swift
//  GoZayanProject
//

import Foundation

nonisolated protocol HTTPClient: Sendable {
    /// Sends the endpoint's request and returns the body of a 2xx response.
    /// Throws `RequestError` for transport failures and non-2xx statuses.
    func data(for endpoint: Endpoint) async throws -> Data
}

/// `HTTPClient` backed by `URLSession`. The session is injected rather than hard-coded.
///
/// Rewritten from the original client, which built a `URLRequest` and then sent a
/// bare URL instead (dropping method and headers), cached inside the client with
/// no expiry, and collapsed every failure into `.unknown` (spec A-01…A-07).
nonisolated struct URLSessionHTTPClient: HTTPClient {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for endpoint: Endpoint) async throws -> Data {
        let request = try endpoint.makeURLRequest()

        let result: (Data, URLResponse)
        do {
            result = try await session.data(for: request)
        } catch let error as URLError {
            throw RequestError(error)
        }

        guard let response = result.1 as? HTTPURLResponse else {
            throw RequestError.invalidResponse
        }

        switch response.statusCode {
        case 200..<300:
            return result.0
        case 401, 403:
            throw RequestError.unauthorized(statusCode: response.statusCode)
        case 429:
            throw RequestError.rateLimited
        default:
            #if DEBUG
            // SerpApi explains 4xx errors in the body ({"error": "..."}). Never log the URL: it holds the API key.
            print("[HTTP] \(response.statusCode) \(request.url?.path ?? ""): \(String(decoding: result.0.prefix(300), as: UTF8.self))")
            #endif
            throw RequestError.server(statusCode: response.statusCode)
        }
    }
}
