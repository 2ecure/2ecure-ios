//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

nonisolated protocol CompoundHookProtocol: Sendable {
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors)
}

/// 2ecure is black and white: Compound's green accents take the neutral values Compound itself uses for primary
/// text, icons and actions, and its green gradients become solid or grey, so both appearances stay consistent.
/// Success, critical and info colours are unchanged. Android applies the same mapping in DefaultEnterpriseService.
struct DefaultCompoundHook: CompoundHookProtocol {
    func override(colors: CompoundColors, uiColors: CompoundUIColors) {
        colors.override(\.bgAccentRest, with: colors.bgActionPrimaryRest)
        uiColors.override(\.bgAccentRest, with: uiColors.bgActionPrimaryRest)
        colors.override(\.bgAccentSelected, with: colors.bgActionSecondaryPressed)
        uiColors.override(\.bgAccentSelected, with: uiColors.bgActionSecondaryPressed)
        colors.override(\.bgBadgeAccent, with: colors.bgSubtleSecondary)
        uiColors.override(\.bgBadgeAccent, with: uiColors.bgSubtleSecondary)
        colors.override(\.borderAccentPrimary, with: colors.iconPrimary)
        uiColors.override(\.borderAccentPrimary, with: uiColors.iconPrimary)
        colors.override(\.borderAccentSubtle, with: colors.borderInteractiveSecondary)
        uiColors.override(\.borderAccentSubtle, with: uiColors.borderInteractiveSecondary)
        colors.override(\.iconAccentPrimary, with: colors.iconPrimary)
        uiColors.override(\.iconAccentPrimary, with: uiColors.iconPrimary)
        colors.override(\.iconAccentTertiary, with: colors.iconPrimary)
        uiColors.override(\.iconAccentTertiary, with: uiColors.iconPrimary)
        colors.override(\.textActionAccent, with: colors.textActionPrimary)
        uiColors.override(\.textActionAccent, with: uiColors.textActionPrimary)
        colors.override(\.textBadgeAccent, with: colors.textPrimary)
        uiColors.override(\.textBadgeAccent, with: uiColors.textPrimary)
        
        // Super and send buttons: solid instead of the green gradient.
        colors.override(\.gradientActionStop1, with: colors.bgActionPrimaryRest)
        colors.override(\.gradientActionStop2, with: colors.bgActionPrimaryRest)
        colors.override(\.gradientActionStop3, with: colors.bgActionPrimaryRest)
        colors.override(\.gradientActionStop4, with: colors.bgActionPrimaryRest)
        
        // Home screen bloom and highlighted messages: translucent grey instead of translucent green.
        colors.override(\.gradientSubtleStop1, with: colors.bgActionSecondaryPressed)
        colors.override(\.gradientSubtleStop2, with: colors.bgActionSecondaryHovered)
        colors.override(\.gradientSubtleStop3, with: colors.bgActionSecondaryHovered.opacity(0.66))
        colors.override(\.gradientSubtleStop4, with: colors.bgActionSecondaryHovered.opacity(0.33))
        colors.override(\.gradientSubtleStop5, with: colors.bgActionSecondaryHovered.opacity(0.15))
    }
}
