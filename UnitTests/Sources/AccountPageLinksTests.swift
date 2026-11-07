//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct AccountPageLinksTests {
    @Test("Account pages opened from the app are marked")
    func accountPagesAreMarked() throws {
        let account = try #require(URL(string: "https://account.2ecure.com/account/"))
        #expect(AccountPageLinks.appURL(account).absoluteString == "https://account.2ecure.com/account/#2ecure-app=ios")
        let action = try #require(URL(string: "https://account.2ecure.com/account/?action=org.matrix.profile"))
        #expect(AccountPageLinks.appURL(action).absoluteString == "https://account.2ecure.com/account/?action=org.matrix.profile#2ecure-app=ios")
    }
    
    @Test("Other pages and URLs with a fragment are unchanged")
    func otherPagesAreUnchanged() throws {
        let other = try #require(URL(string: "https://example.org/account/"))
        #expect(AccountPageLinks.appURL(other) == other)
        let withFragment = try #require(URL(string: "https://account.2ecure.com/account/#section"))
        #expect(AccountPageLinks.appURL(withFragment) == withFragment)
    }
    
    @Test("Only the app's signed-out callback counts as a sign-out")
    func signedOutCallback() throws {
        let redirectURL = try #require(URL(string: "com.2ecure.chat:/oauth/callback"))
        #expect(try AccountPageLinks.isSignedOutCallback(#require(URL(string: "com.2ecure.chat:/signed-out")), redirectURL: redirectURL))
        #expect(try !AccountPageLinks.isSignedOutCallback(#require(URL(string: "com.2ecure.chat:/oauth/callback?code=1")), redirectURL: redirectURL))
        #expect(try !AccountPageLinks.isSignedOutCallback(#require(URL(string: "other.app:/signed-out")), redirectURL: redirectURL))
    }
}
