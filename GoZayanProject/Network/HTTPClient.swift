//
//  HTTPClient.swift
//  BS24TestProject
//
//  Created by ArifAhmed on 30/10/24.
//

import Foundation

protocol HTTPClient {
    func sendRequest<T : Decodable>(endpoint : Endpoint, responseModel : T.Type) async -> Result<T, RequestError>
}

extension HTTPClient {
    func sendRequest<T : Decodable>(endpoint : Endpoint, responseModel : T.Type) async -> Result<T, RequestError> {
        var urlComponents = URLComponents()
        urlComponents.scheme = endpoint.scheme
        urlComponents.host = endpoint.host
        urlComponents.path = endpoint.path
        urlComponents.queryItems = endpoint.queryItems
        guard let url = urlComponents.url else {
            return .failure(.invalidURL)
        }
        if let cachedData = URLSession.shared.configuration.urlCache?.cachedResponse(for: URLRequest(url: url))?.data, let decodedResponse = try? JSONDecoder().decode(responseModel.self, from: cachedData) {
            return .success(decodedResponse)
        }
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.allHTTPHeaderFields = endpoint.header
        request.cachePolicy = .returnCacheDataElseLoad
        if let body = endpoint.body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let response = response as? HTTPURLResponse else {
                return .failure(.noResponse)
            }
            switch response.statusCode {
            case 200...299:
                let cachedResponse = CachedURLResponse(response: response, data: data)
                URLSession.shared.configuration.urlCache?.storeCachedResponse(cachedResponse, for: URLRequest(url: url))
                guard let decodedResponse = try? JSONDecoder().decode(responseModel.self, from: data) else {
                    return .failure(.decode)
                }
                  
                return .success(decodedResponse)
            case 401:
                return .failure(.unauthorized)
            default:
                return .failure(.unexpectedStatus)
            }
        } catch {
            return .failure(.unknown)
        }
    }
}

extension URLSession {
    func data(from url : URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation({ continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    return continuation.resume(throwing: error ?? URLError(.badServerResponse))
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        })
    }
}
