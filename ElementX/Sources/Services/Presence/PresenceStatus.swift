//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// 2ecure: someone's online status as the homeserver reports it (docs/privacy.md).
nonisolated struct PresenceStatus: Equatable, Sendable {
    let isOnline: Bool
    /// When the person was last active, if the homeserver knows.
    let lastActive: Date?
    
    init(isOnline: Bool, lastActive: Date?) {
        self.isOnline = isOnline
        self.lastActive = lastActive
    }
    
    /// Parses the body of `GET /_matrix/client/v3/presence/{userId}/status`.
    init?(json: Data, now: Date = .now) {
        guard let object = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let presence = object["presence"] as? String else {
            return nil
        }
        isOnline = presence == "online"
        lastActive = (object["last_active_ago"] as? NSNumber).map { now.addingTimeInterval(-$0.doubleValue / 1000) }
    }
    
    /// «Online» or «Last seen 5 minutes ago»; `nil` when nothing is known.
    func subtitle(relativeTo now: Date = .now) -> String? {
        if isOnline {
            return TwoEcureL10n.tr("presence_online")
        }
        guard let lastActive else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return TwoEcureL10n.tr("presence_last_seen", formatter.localizedString(for: min(lastActive, now), relativeTo: now))
    }
}

/// 2ecure: other people's online status. The Rust SDK sets the own presence but cannot read anyone's, so this asks
/// the homeserver, at most once a minute per person; Synapse answers only for people who share a room.
final class PresenceStatusStore {
    private static var stores: [String: PresenceStatusStore] = [:]
    
    static func shared(for clientProxy: ClientProxyProtocol) -> PresenceStatusStore {
        let store = stores[clientProxy.userID] ?? PresenceStatusStore()
        store.clientProxy = clientProxy
        stores[clientProxy.userID] = store
        return store
    }
    
    private static let maximumAge: TimeInterval = 50
    
    private weak var clientProxy: ClientProxyProtocol?
    private var fetched: [String: Date] = [:]
    private var inFlight: Set<String> = []
    private let statusesSubject = CurrentValueSubject<[String: PresenceStatus], Never>([:])
    
    var statusesPublisher: CurrentValuePublisher<[String: PresenceStatus], Never> {
        statusesSubject.asCurrentValuePublisher()
    }
    
    func status(for userID: String) -> PresenceStatus? {
        statusesSubject.value[userID]
    }
    
    /// Asks the homeserver for the people whose status is older than a minute.
    func refresh(_ userIDs: [String]) async {
        let now = Date.now
        let due = userIDs.filter { userID in
            !inFlight.contains(userID) && fetched[userID].map { now.timeIntervalSince($0) > Self.maximumAge } ?? true
        }
        inFlight.formUnion(due)
        defer { inFlight.subtract(due) }
        
        for userID in due {
            guard let clientProxy, !Task.isCancelled else { return }
            switch await clientProxy.presence(of: userID) {
            case .success(let status):
                fetched[userID] = .now
                statusesSubject.value[userID] = status
            case .failure:
                // Unknown, e.g. while the access token is being refreshed: keep the last answer, ask again next time.
                break
            }
        }
    }
}
