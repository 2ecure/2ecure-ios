//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct InvitationLinksTests {
    @Test
    func invitationQRCodes() {
        #expect(code("https://account.2ecure.com/register#code=vGj3hez2sjnk") == "vGj3hez2sjnk")
        #expect(code("HTTPS://Account.2ecure.com/register/#code=abc%2Ddef") == "abc-def")
        #expect(code("https://account.2ecure.com/register#lang=de&code=abc123\n") == "abc123")
    }
    
    @Test
    func otherQRCodesAreNotInvitations() {
        #expect(code("https://account.2ecure.com/register") == nil)
        #expect(code("https://account.2ecure.com/register#code=") == nil)
        #expect(code("https://account.2ecure.com/login#code=abc123") == nil)
        #expect(code("https://example.org/register#code=abc123") == nil)
        #expect(code("http://account.2ecure.com/register#code=abc123") == nil)
        #expect(InvitationLinks.invitationCode(fromQRCode: Data([0x4D, 0x41, 0x54, 0x52, 0x49, 0x58, 0x03, 0x00, 0xFF])) == nil)
    }
    
    @Test
    func registrationURLCarriesTheCode() throws {
        let url = try #require(URL(string: "https://account.2ecure.com/authorize?client_id=abc&prompt=create"))
        #expect(InvitationLinks.url(url, withInvitationCode: "vGj3hez2sjnk").absoluteString == "https://account.2ecure.com/authorize?client_id=abc&prompt=create#code=vGj3hez2sjnk")
        #expect(InvitationLinks.url(url, withInvitationCode: "a b&c").absoluteString == "https://account.2ecure.com/authorize?client_id=abc&prompt=create#code=a%20b%26c")
    }
    
    // MARK: - Helpers
    
    private func code(_ text: String) -> String? {
        InvitationLinks.invitationCode(fromQRCode: Data(text.utf8))
    }
}
