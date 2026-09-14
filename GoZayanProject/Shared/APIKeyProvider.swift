//
//  APIKeyProvider.swift
//  GoZayanProject
//

import Foundation

/// Reads the SerpApi key from `Config/Secrets.plist`, which is git-ignored (spec KEY-01, KEY-02).
/// See `Secrets.example.plist` at the repo root.
///
/// A key shipped inside an app can be extracted from the binary; a production app
/// would call its own backend instead (KEY-06).
nonisolated enum APIKeyProvider {

    static func serpApiKey(in bundle: Bundle = .main) -> String? {
        guard let url = bundle.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let values = try? PropertyListDecoder().decode([String: String].self, from: data),
              let key = values["SerpApiKey"]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !key.isEmpty, key != "YOUR_SERPAPI_KEY" else {
            return nil
        }
        return key
    }
}
