//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

/// 2ecure: who can find you and the online status (docs/privacy.md).
struct TwoEcurePrivacyTests {
    @Test("Only a JSON boolean counts as a choice, as on the server")
    func discoverableParsing() {
        #expect(PrivacyChoice.discoverable(fromJSON: #"{"discoverable":true}"#) == true)
        #expect(PrivacyChoice.discoverable(fromJSON: #"{"discoverable":false}"#) == false)
        #expect(PrivacyChoice.discoverable(fromJSON: #"{"discoverable":1}"#) == nil)
        #expect(PrivacyChoice.discoverable(fromJSON: #"{"discoverable":"yes"}"#) == nil)
        #expect(PrivacyChoice.discoverable(fromJSON: "{}") == nil)
        #expect(PrivacyChoice.discoverable(fromJSON: "not JSON") == nil)
    }
    
    @Test("A written choice reads back the same")
    func discoverableRoundTrip() {
        #expect(PrivacyChoice.discoverable(fromJSON: PrivacyChoice.json(discoverable: true)) == true)
        #expect(PrivacyChoice.discoverable(fromJSON: PrivacyChoice.json(discoverable: false)) == false)
    }
    
    @Test("The homeserver's presence answer becomes online or last seen")
    func presenceParsing() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        
        let online = try #require(PresenceStatus(json: Data(#"{"presence":"online","last_active_ago":5000,"currently_active":true}"#.utf8), now: now))
        #expect(online.isOnline)
        #expect(online.lastActive == now.addingTimeInterval(-5))
        #expect(online.subtitle(relativeTo: now) != nil)
        
        let offline = try #require(PresenceStatus(json: Data(#"{"presence":"offline","last_active_ago":600000}"#.utf8), now: now))
        #expect(!offline.isOnline)
        #expect(offline.lastActive == now.addingTimeInterval(-600))
        #expect(offline.subtitle(relativeTo: now) != nil)
        
        #expect(PresenceStatus(isOnline: false, lastActive: nil).subtitle(relativeTo: now) == nil)
        #expect(PresenceStatus(json: Data("{}".utf8)) == nil)
    }
}
