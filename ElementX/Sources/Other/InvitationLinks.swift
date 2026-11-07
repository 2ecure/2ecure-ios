//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// 2ecure: the personal invitation link `https://account.2ecure.com/register#code=<invitation code>`, which invitations
/// carry as text and as a QR code. Scanned with «Scan QR code», it creates the account in the app: the account
/// server's registration opens with the same `#code=`, and 2ecure's account pages put it into the invitation code field.
nonisolated enum InvitationLinks {
    private static let registrationHost = "account.2ecure.com"
    private static let registrationPaths: Set = ["/register", "/register/"]
    /// RFC 3986 unreserved characters: a code made of them is sent exactly as the invitation link writes it.
    private static let codeCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    
    /// The invitation code in a scanned QR code, or `nil` when it isn't a 2ecure invitation link.
    static func invitationCode(fromQRCode data: Data) -> String? {
        guard let text = String(data: data, encoding: .utf8),
              let components = URLComponents(string: text.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "https",
              components.host?.lowercased() == registrationHost,
              registrationPaths.contains(components.path),
              let fragment = components.percentEncodedFragment else {
            return nil
        }
        
        let code = fragment.split(separator: "&")
            .first(where: { $0.hasPrefix("code=") })?
            .dropFirst("code=".count)
            .removingPercentEncoding?
            .trimmingCharacters(in: .whitespaces)
        guard let code, !code.isEmpty else { return nil }
        return code
    }
    
    /// The registration `url` with the invitation code in its fragment, as the invitation link carries it.
    static func url(_ url: URL, withInvitationCode code: String) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let encodedCode = code.addingPercentEncoding(withAllowedCharacters: codeCharacters) else {
            return url
        }
        components.percentEncodedFragment = "code=\(encodedCode)"
        return components.url ?? url
    }
}
