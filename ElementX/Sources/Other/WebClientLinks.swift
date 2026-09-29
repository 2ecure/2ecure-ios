//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// 2ecure: links people share (profile, room, space, message, invite text) point at the web client, in Element Web's
/// own format, instead of matrix.to, which does not know the closed 2ecure service. The apps and Element Web open
/// these links; people without the app land in the web client.
///
/// - `https://matrix.to/#/@alice:2ecure.com` → `https://chat.2ecure.com/#/user/@alice:2ecure.com`
/// - `https://matrix.to/#/!room:2ecure.com/$event?via=2ecure.com` → `https://chat.2ecure.com/#/room/!room:2ecure.com/$event?via=2ecure.com`
///
/// Anything that is not a matrix.to link is returned unchanged. Mentions inside messages keep matrix.to links, which
/// every Matrix client understands.
nonisolated enum WebClientLinks {
    static let webClientBaseURL = "https://chat.2ecure.com/#/"
    private static let matrixToBaseURL = "https://matrix.to/#/"
    
    static func fromMatrixTo(_ permalink: String) -> String {
        guard permalink.hasPrefix(matrixToBaseURL) else { return permalink }
        let entity = permalink.dropFirst(matrixToBaseURL.count)
        let kind = entity.hasPrefix("@") || entity.hasPrefix("%40") ? "user" : "room"
        return "\(webClientBaseURL)\(kind)/\(entity)"
    }
}
