//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import UIKit

nonisolated protocol CompoundHookProtocol: Sendable {
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors)
}

struct DefaultCompoundHook: CompoundHookProtocol {
    func override(colors: CompoundColors, uiColors: CompoundUIColors) {
        // TODO: Final brand colours go here and in colors/accent-color.colorset.
        // Placeholder #0B5FFF is intentionally identical in light and dark appearance.
        let accent = UIColor(red: 11.0 / 255.0, green: 95.0 / 255.0, blue: 1, alpha: 1)
        colors.override(\.textActionPrimary, with: Color(uiColor: accent))
        uiColors.override(\.textActionPrimary, with: accent)
        colors.override(\.bgActionPrimaryRest, with: Color(uiColor: accent))
        uiColors.override(\.bgActionPrimaryRest, with: accent)
        colors.override(\.bgActionPrimaryPressed, with: Color(uiColor: accent))
        uiColors.override(\.bgActionPrimaryPressed, with: accent)
        colors.override(\.iconAccentPrimary, with: Color(uiColor: accent))
        uiColors.override(\.iconAccentPrimary, with: accent)
        colors.override(\.iconAccentTertiary, with: Color(uiColor: accent))
        uiColors.override(\.iconAccentTertiary, with: accent)
    }
}
