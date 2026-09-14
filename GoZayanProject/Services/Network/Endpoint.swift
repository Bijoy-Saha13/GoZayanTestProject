//
//  Endpoint.swift
//  GoZayanProject
//

import Foundation

/// Describes one HTTP request. Concrete endpoints only state what differs.
nonisolated protocol Endpoint: Sendable {
    var scheme: String { get }
    var host: String { get }
    var path: String { get }
    var method: RequestMethod { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
}

nonisolated extension Endpoint {
    var scheme: String { "https" }
    var method: RequestMethod { .get }
    var headers: [String: String] { ["Accept": "application/json"] }

    /// Builds the request with query values encoded by `URLComponents` (DATA-06)
    /// and a 30 s timeout (NFR-05).
    func makeURLRequest(timeout: TimeInterval = 30) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        guard let url = components.url else { throw RequestError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
        return request
    }
}
