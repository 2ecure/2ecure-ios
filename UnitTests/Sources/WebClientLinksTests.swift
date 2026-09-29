//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct WebClientLinksTests {
    @Test
    func userLinks() {
        #expect(WebClientLinks.fromMatrixTo("https://matrix.to/#/@alice:2ecure.com") == "https://chat.2ecure.com/#/user/@alice:2ecure.com")
        #expect(WebClientLinks.fromMatrixTo("https://matrix.to/#/%40alice%3A2ecure.com") == "https://chat.2ecure.com/#/user/%40alice%3A2ecure.com")
    }
    
    @Test
    func roomAliasAndEventLinks() {
        #expect(WebClientLinks.fromMatrixTo("https://matrix.to/#/!room:2ecure.com?via=2ecure.com") == "https://chat.2ecure.com/#/room/!room:2ecure.com?via=2ecure.com")
        #expect(WebClientLinks.fromMatrixTo("https://matrix.to/#/%23team:2ecure.com") == "https://chat.2ecure.com/#/room/%23team:2ecure.com")
        #expect(WebClientLinks.fromMatrixTo("https://matrix.to/#/!room:2ecure.com/$event?via=2ecure.com") == "https://chat.2ecure.com/#/room/!room:2ecure.com/$event?via=2ecure.com")
    }
    
    @Test
    func otherLinksAreUnchanged() {
        #expect(WebClientLinks.fromMatrixTo("https://example.org/page") == "https://example.org/page")
    }
}
