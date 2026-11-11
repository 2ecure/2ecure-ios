//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// 2ecure: who can find the account in the user search (docs/privacy.md). The choice is the global account data
/// `com.2ecure.privacy` = `{"discoverable": Bool}`, which the server's `twoecure_privacy` module reads.
enum PrivacyChoice {
    static let eventType = "com.2ecure.privacy"
    
    /// `true` for «Everyone on 2ecure», `false` for «Only people I chat with», `nil` while the account hasn't chosen.
    static func discoverable(clientProxy: ClientProxyProtocol) async -> Result<Bool?, ClientProxyError> {
        switch await clientProxy.accountData(eventType: eventType) {
        case .success(let json):
            .success(json.flatMap(discoverable(fromJSON:)))
        case .failure(let error):
            .failure(error)
        }
    }
    
    static func setDiscoverable(_ discoverable: Bool, clientProxy: ClientProxyProtocol) async -> Bool {
        guard case .success = await clientProxy.setAccountData(eventType: eventType, content: json(discoverable: discoverable)) else {
            return false
        }
        return true
    }
    
    /// Only a JSON boolean counts, as on the server.
    nonisolated static func discoverable(fromJSON json: String) -> Bool? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let number = object["discoverable"] as? NSNumber,
              CFGetTypeID(number) == CFBooleanGetTypeID() else {
            return nil
        }
        return number.boolValue
    }
    
    nonisolated static func json(discoverable: Bool) -> String {
        "{\"discoverable\":\(discoverable)}"
    }
}
