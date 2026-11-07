//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// 2ecure: the account pages (account.2ecure.com) use the phone's web sign-in, which can belong to another account
/// than the app's, and their «Sign out of account» only ended that web sign-in. The app opens them with
/// `#2ecure-app=ios&user=<its Matrix ID>`; 2ecure's account page templates (`components/2ecure_app_signout.html`)
/// then cover the page when the web sign-in is another account, and after a sign-out there send the web view to
/// `com.2ecure.chat:/signed-out`, which ends the web authentication session, and the app signs out as well.
nonisolated enum AccountPageLinks {
    private static let accountHost = "account.2ecure.com"
    private static let appMarker = "2ecure-app=ios"
    private static let signedOutPath = "/signed-out"
    /// RFC 3986 unreserved characters; everything else in the Matrix ID is percent-encoded.
    private static let fragmentValueCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")

    /// The account page `url`, marked as opened from the app by `userID` (unchanged for other hosts or with a fragment already).
    static func appURL(_ url: URL, userID: String) -> URL {
        guard url.host()?.lowercased() == accountHost,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.fragment == nil,
              let encodedUserID = userID.addingPercentEncoding(withAllowedCharacters: fragmentValueCharacters) else {
            return url
        }
        components.percentEncodedFragment = "\(appMarker)&user=\(encodedUserID)"
        return components.url ?? url
    }

    /// Whether the account page ended the web authentication session because the person signed out there.
    static func isSignedOutCallback(_ url: URL, redirectURL: URL) -> Bool {
        url.scheme == redirectURL.scheme && url.path() == signedOutPath
    }
}
