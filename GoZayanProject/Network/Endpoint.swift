//
//  Endpoint.swift
//  BS24TestProject
//
//  Created by ArifAhmed on 30/10/24.
//

import Foundation

protocol Endpoint {
    var scheme : String { get }
    var host : String { get }
    var path : String { get }
    var method : RequestMethod { get }
    var header : [String : String]? { get }
    var body : [String : String]? { get }
    var queryItems : [URLQueryItem]? { get }
}
