//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol AppSettingsHookProtocol: Sendable {
    @MainActor func configure(_ appSettings: AppSettings) -> AppSettings
}

struct DefaultAppSettingsHook: AppSettingsHookProtocol {
    func configure(_ appSettings: AppSettings) -> AppSettings {
        appSettings.override(accountProviders: [.managed(serverName: "2ecure.com", baseURL: "https://matrix.2ecure.com")],
                             allowOtherAccountProviders: false,
                             hideBrandChrome: true,
                             pushGatewayBaseURL: "https://push.2ecure.com",
                             oAuthRedirectURL: "https://2ecure.com/oauth/ios/com.2ecure.chat",
                             oAuthClientURIPath: nil,
                             websiteURL: "https://2ecure.com",
                             logoURL: "https://2ecure.com/logo-512.png",
                             copyrightURL: "https://2ecure.com/source",
                             acceptableUseURL: "https://2ecure.com/agb",
                             privacyURL: "https://2ecure.com/datenschutz",
                             encryptionURL: "https://2ecure.com/hilfe#verschluesselung",
                             deviceVerificationURL: "https://2ecure.com/hilfe#verifizierung",
                             chatBackupDetailsURL: "https://2ecure.com/hilfe#schluesselspeicher",
                             identityPinningViolationDetailsURL: "https://2ecure.com/hilfe#identitaet",
                             historySharingDetailsURL: "https://2ecure.com/hilfe#verlauf",
                             elementWebHosts: ["chat.2ecure.com"],
                             accountProvisioningHost: "2ecure.com",
                             bugReportApplicationID: "2ecure-ios",
                             analyticsTermsURL: nil,
                             mapTilerConfiguration: .init(baseURL: "https://2ecure.com", apiKey: nil, lightStyleID: "", darkStyleID: ""))
        return appSettings
    }
}
