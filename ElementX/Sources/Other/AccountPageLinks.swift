//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// 2ecure: «Sign out of account» on the account pages (account.2ecure.com) only ended the web session there, so the app
/// stayed signed in. The app opens these pages with `#2ecure-app=ios`; 2ecure's account page templates
/// (`components/2ecure_app_signout.html`) then send the web view to `com.2ecure.chat:/signed-out` after a sign-out,
/// which ends the web authentication session, and the app signs out as well.
nonisolated enum AccountPageLinks {
    private static let accountHost = "account.2ecure.com"
    private static let appMarker = "2ecure-app=ios"
    private static let signedOutPath = "/signed-out"

    /// The account page `url`, marked as opened from the app (unchanged for other hosts or with a fragment already).
    static func appURL(_ url: URL) -> URL {
        guard url.host()?.lowercased() == accountHost,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.fragment == nil else {
            return url
        }
        components.percentEncodedFragment = appMarker
        return components.url ?? url
    }

    /// Whether the account page ended the web authentication session because the person signed out there.
    static func isSignedOutCallback(_ url: URL, redirectURL: URL) -> Bool {
        url.scheme == redirectURL.scheme && url.path() == signedOutPath
    }
}
