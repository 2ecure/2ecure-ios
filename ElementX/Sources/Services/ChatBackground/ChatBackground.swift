//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ImageIO
import SwiftUI

/// 2ecure: a background behind one chat's timeline that only the account's owner sees. An account's choices live in
/// the global account data event `com.2ecure.chat_backgrounds`, so they follow it to its other devices. The format is
/// shared with the Android app (docs/chat-backgrounds.md in the 2ecure repository):
/// `{"rooms": {"!room:2ecure.com": {"type": "gradient", "id": "sky"}, "!other:2ecure.com": {"type": "pattern",
/// "id": "regal", "colour": "#DCE6F2"}}}`.
nonisolated enum ChatBackground: Equatable, Sendable {
    case gradient(ChatBackgroundGradient)
    case customGradient(top: ChatBackgroundColour, bottom: ChatBackgroundColour)
    case colour(ChatBackgroundColour)
    case pattern(ChatBackgroundPattern, colour: ChatBackgroundColour)
    case image(url: String, mimeType: String?)
    
    /// One room's entry; `nil` for a kind, gradient or pattern this version doesn't know.
    init?(json: [String: Any]) {
        switch json["type"] as? String {
        case "gradient":
            if let id = json["id"] as? String {
                guard let gradient = ChatBackgroundGradient(rawValue: id) else { return nil }
                self = .gradient(gradient)
            } else {
                guard let hexes = json["colours"] as? [String], hexes.count == 2,
                      let top = ChatBackgroundColour(hex: hexes[0]), let bottom = ChatBackgroundColour(hex: hexes[1]) else {
                    return nil
                }
                self = .customGradient(top: top, bottom: bottom)
            }
        case "colour":
            guard let colour = (json["colour"] as? String).flatMap(ChatBackgroundColour.init(hex:)) else { return nil }
            self = .colour(colour)
        case "pattern":
            guard let pattern = (json["id"] as? String).flatMap(ChatBackgroundPattern.init(rawValue:)),
                  let colour = (json["colour"] as? String).flatMap(ChatBackgroundColour.init(hex:)) else {
                return nil
            }
            self = .pattern(pattern, colour: colour)
        case "image":
            guard let url = json["url"] as? String, url.hasPrefix("mxc://") else { return nil }
            self = .image(url: url, mimeType: json["mimetype"] as? String)
        default:
            return nil
        }
    }
    
    var json: [String: Any] {
        switch self {
        case .gradient(let gradient):
            ["type": "gradient", "id": gradient.rawValue]
        case .customGradient(let top, let bottom):
            ["type": "gradient", "colours": [top.hex, bottom.hex]]
        case .colour(let colour):
            ["type": "colour", "colour": colour.hex]
        case .pattern(let pattern, let colour):
            ["type": "pattern", "id": pattern.rawValue, "colour": colour.hex]
        case .image(let url, let mimeType):
            ["type": "image", "url": url, "mimetype": mimeType ?? "image/jpeg"]
        }
    }
    
    /// The backgrounds by room ID in an account data content.
    static func backgrounds(in content: [String: Any]) -> [String: ChatBackground] {
        let rooms = content["rooms"] as? [String: Any] ?? [:]
        return rooms.compactMapValues { ($0 as? [String: Any]).flatMap(ChatBackground.init(json:)) }
    }
    
    /// The content with one room's entry replaced (or removed for `nil`); keys this version doesn't know stay.
    static func content(_ content: [String: Any], setting background: ChatBackground?, for roomID: String) -> [String: Any] {
        self.content(content, settingEntry: background?.json, for: roomID)
    }
    
    static func content(_ content: [String: Any], settingEntry entry: [String: Any]?, for roomID: String) -> [String: Any] {
        var content = content
        var rooms = content["rooms"] as? [String: Any] ?? [:]
        rooms[roomID] = entry
        content["rooms"] = rooms
        return content
    }
}

/// 2ecure: a colour chosen for a chat background, stored as `#RRGGBB`.
nonisolated struct ChatBackgroundColour: Hashable, Sendable {
    let rgb: UInt32
    
    init(rgb: UInt32) {
        self.rgb = rgb & 0xFFFFFF
    }
    
    init?(hex: String) {
        guard hex.count == 7, hex.hasPrefix("#"), let rgb = UInt32(hex.dropFirst(), radix: 16) else { return nil }
        self.init(rgb: rgb)
    }
    
    init(_ color: Color) {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func channel(_ value: CGFloat) -> UInt32 {
            UInt32((min(max(value, 0), 1) * 255).rounded())
        }
        self.init(rgb: channel(red) << 16 | channel(green) << 8 | channel(blue))
    }
    
    var hex: String {
        String(format: "#%06X", rgb)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    /// The colour patterns draw in: the base very slightly darker, or lighter when the base is dark (5 % / 6 %).
    var motif: ChatBackgroundColour {
        let luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
        let shift: (Double) -> Double = luminance > 0.5 ? { $0 * 0.95 } : { $0 + 0.06 * (1 - $0) }
        func channel(_ value: Double) -> UInt32 {
            UInt32((shift(value) * 255).rounded())
        }
        return ChatBackgroundColour(rgb: channel(red) << 16 | channel(green) << 8 | channel(blue))
    }
    
    private var red: Double {
        Double((rgb >> 16) & 0xFF) / 255
    }
    
    private var green: Double {
        Double((rgb >> 8) & 0xFF) / 255
    }
    
    private var blue: Double {
        Double(rgb & 0xFF) / 255
    }
    
    static let defaultColour = ChatBackgroundColour(rgb: 0x5B8DEF)
    static let defaultGradientBottom = ChatBackgroundColour(rgb: 0xB57BEE)
    static let defaultPatternColour = ChatBackgroundColour(rgb: 0xDCE6F2)
}

/// 2ecure: the built-in backgrounds, top-to-bottom gradients in a light and a dark variant.
nonisolated enum ChatBackgroundGradient: String, CaseIterable, Identifiable, Sendable {
    case sky, sea, forest, sand, rose, lavender
    
    var id: String {
        rawValue
    }
    
    var name: String {
        TwoEcureL10n.tr("chat_background_\(rawValue)")
    }
    
    func colours(isDark: Bool) -> [Color] {
        let (top, bottom): (UInt32, UInt32) = switch (self, isDark) {
        case (.sky, false): (0xD9E8F8, 0xF4F8FD)
        case (.sky, true): (0x14263A, 0x0B121B)
        case (.sea, false): (0xD3EFEA, 0xF2FAF8)
        case (.sea, true): (0x10302C, 0x0A1614)
        case (.forest, false): (0xDDEFD5, 0xF4FAF1)
        case (.forest, true): (0x1A2E1E, 0x0C150F)
        case (.sand, false): (0xF4E6D0, 0xFBF7F0)
        case (.sand, true): (0x2E2617, 0x16120B)
        case (.rose, false): (0xF6DAE3, 0xFCF2F5)
        case (.rose, true): (0x33202A, 0x170E13)
        case (.lavender, false): (0xE4DDF6, 0xF6F3FC)
        case (.lavender, true): (0x231D3A, 0x100D1A)
        }
        return [ChatBackgroundColour(rgb: top).color, ChatBackgroundColour(rgb: bottom).color]
    }
}

/// 2ecure: patterns drawn in code over a base colour (ChatBackgroundPatternView).
nonisolated enum ChatBackgroundPattern: String, CaseIterable, Identifiable, Sendable {
    case regal, dots, stripes, checks, waves, zigzag, stars
    
    var id: String {
        rawValue
    }
    
    var name: String {
        TwoEcureL10n.tr("chat_background_pattern_\(rawValue)")
    }
}

/// 2ecure: the chat backgrounds of one account, shared by its chat screens and chat settings.
///
/// Writes replace the whole event, so they start from the content in the SDK's store, which sync keeps up to date.
/// Until sync brings a write back, that content is older than the write: this device's edits stay on top of it until
/// the store has them, or until another device has changed the same chat since.
final class ChatBackgroundStore {
    static let eventType = "com.2ecure.chat_backgrounds"
    
    private static var stores = [String: ChatBackgroundStore]()
    
    private weak var clientProxy: ClientProxyProtocol?
    private let backgroundsSubject = CurrentValueSubject<[String: ChatBackground], Never>([:])
    /// The content as last read from the SDK's store.
    private var storedContent = [String: Any]()
    private var pendingEdits = [String: ChatBackgroundEdit]()
    
    // One read-modify-write at a time: main actor isolation alone lets another one start at every `await`.
    private var isBusy = false
    private var waiters = [CheckedContinuation<Void, Never>]()
    
    static func shared(for clientProxy: ClientProxyProtocol) -> ChatBackgroundStore {
        let store = stores[clientProxy.userID] ?? ChatBackgroundStore()
        store.clientProxy = clientProxy
        stores[clientProxy.userID] = store
        return store
    }
    
    func background(for roomID: String) -> ChatBackground? {
        backgroundsSubject.value[roomID]
    }
    
    func backgroundPublisher(for roomID: String) -> AnyPublisher<ChatBackground?, Never> {
        backgroundsSubject
            .map { $0[roomID] }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    /// Reads the account data from the SDK's store.
    func refresh() async {
        await lock()
        defer { unlock() }
        _ = await readStoredContent()
    }
    
    func setBackground(_ background: ChatBackground?, for roomID: String) async -> Bool {
        await lock()
        defer { unlock() }
        
        // Without the current content, the write would replace the other chats' backgrounds.
        guard await readStoredContent(), let clientProxy else { return false }
        
        let content = ChatBackground.content(currentContent, setting: background, for: roomID)
        guard let data = try? JSONSerialization.data(withJSONObject: content, options: .sortedKeys),
              let json = String(data: data, encoding: .utf8) else {
            return false
        }
        guard case .success = await clientProxy.setAccountData(eventType: Self.eventType, content: json) else {
            return false
        }
        
        // Earlier writes of this device that sync may still bring back count as old, too.
        let earlierWrites = pendingEdits[roomID].map { $0.superseded + [$0.entry] } ?? []
        let storedEntry = ChatBackgroundEdit.entry(in: storedContent, for: roomID)
        pendingEdits[roomID] = ChatBackgroundEdit(entry: background?.json, superseded: earlierWrites + [storedEntry])
        publish()
        return true
    }
    
    /// Shrinks a picked photo, re-encodes it without its metadata (camera, location) and uploads it, unencrypted.
    func uploadPhoto(_ data: Data) async -> ChatBackground? {
        guard let clientProxy,
              let jpeg = await Task.detached(operation: { Self.preparedJPEG(from: data) }).value,
              case .success(let url) = await clientProxy.uploadMedia(data: jpeg, mimeType: "image/jpeg") else {
            MXLog.error("Failed preparing or uploading a chat background photo")
            return nil
        }
        return .image(url: url, mimeType: "image/jpeg")
    }
    
    /// A JPEG of at most `maxPixelSize` on the long side, upright, without the original's metadata.
    nonisolated static func preparedJPEG(from data: Data, maxPixelSize: Int = 2048) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceCreateThumbnailWithTransform: true,
                                        kCGImageSourceThumbnailMaxPixelSize: maxPixelSize]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image).jpegData(compressionQuality: 0.8)
    }
    
    // MARK: - Private
    
    /// The stored content with this device's pending edits on top.
    private var currentContent: [String: Any] {
        pendingEdits.reduce(storedContent) { content, edit in
            ChatBackground.content(content, settingEntry: edit.value.entry, for: edit.key)
        }
    }
    
    /// Reads the content from the SDK's store; `false` when it couldn't be read or isn't a JSON object.
    private func readStoredContent() async -> Bool {
        guard let clientProxy, case .success(let json) = await clientProxy.accountData(eventType: Self.eventType) else {
            return false
        }
        let content: [String: Any]
        if let json {
            guard let parsed = Self.parse(json) else {
                MXLog.error("The chat backgrounds account data is not a JSON object")
                return false
            }
            content = parsed
        } else {
            content = [:]
        }
        
        storedContent = content
        pendingEdits = pendingEdits.filter { roomID, edit in
            edit.isPending(storedEntry: ChatBackgroundEdit.entry(in: content, for: roomID))
        }
        publish()
        return true
    }
    
    private func publish() {
        backgroundsSubject.send(ChatBackground.backgrounds(in: currentContent))
    }
    
    private func lock() async {
        if isBusy {
            // unlock() hands the store over without clearing isBusy.
            await withCheckedContinuation { waiters.append($0) }
        } else {
            isBusy = true
        }
    }
    
    private func unlock() {
        if waiters.isEmpty {
            isBusy = false
        } else {
            waiters.removeFirst().resume()
        }
    }
    
    private nonisolated static func parse(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

/// 2ecure: one chat's background as written by this device, until the SDK's store has it.
nonisolated struct ChatBackgroundEdit {
    /// The written entry; `nil` for no background.
    let entry: [String: Any]?
    /// The entries the store had before this device's writes for the chat. While it still has one of them, sync
    /// hasn't brought the latest write back; anything else is that write, or a newer change from another device.
    let superseded: [[String: Any]?]
    
    func isPending(storedEntry: [String: Any]?) -> Bool {
        !Self.isEqual(storedEntry, entry) && superseded.contains { Self.isEqual(storedEntry, $0) }
    }
    
    static func entry(in content: [String: Any], for roomID: String) -> [String: Any]? {
        (content["rooms"] as? [String: Any])?[roomID] as? [String: Any]
    }
    
    private static func isEqual(_ lhs: [String: Any]?, _ rhs: [String: Any]?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): true
        case let (lhs?, rhs?): NSDictionary(dictionary: lhs).isEqual(to: rhs)
        default: false
        }
    }
}

/// 2ecure: strings of 2ecure's own features (`TwoEcure.strings`), looked up like `L10n`'s.
nonisolated enum TwoEcureL10n {
    static func tr(_ key: String) -> String {
        let languages = Bundle.overrideLocalizations ?? Bundle.app.preferredLocalizations
        for language in languages + [Bundle.app.developmentLocalization].compactMap(\.self) {
            guard let bundle = Bundle.lprojBundle(for: language) else { continue }
            let translation = NSLocalizedString(key, tableName: "TwoEcure", bundle: bundle, comment: "")
            if translation != key {
                return translation
            }
        }
        return key
    }
    
    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: tr(key), locale: Locale.current, arguments: arguments)
    }
}
