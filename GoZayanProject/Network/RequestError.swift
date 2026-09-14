//
//  RequestError.swift
//  BS24TestProject
//
//  Created by ArifAhmed on 30/10/24.
//


import UIKit

enum RequestError: Error {
    case decode
    case invalidURL
    case noResponse
    case unauthorized
    case unexpectedStatus
    case unknown
    
    
    var errorMessage: String {
        switch self {
        case .decode:
            return "Decode error"
        case .invalidURL:
            return "Invalid url"
        case .noResponse:
            return "Empty response"
        case .unauthorized:
            return "Unauthorized user"
        case .unexpectedStatus:
            return "Unexpected status code"
        case .unknown:
            return "Unknow  error"
        }
    }
}
