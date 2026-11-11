//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// 2ecure: the green dot on the avatar of someone who is online (docs/privacy.md).
struct OnlineDot: View {
    let size: CGFloat
    
    var body: some View {
        Circle()
            .fill(Color.compound.iconSuccessPrimary)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(Color.compound.bgCanvasDefault, lineWidth: size / 6)
            }
    }
}
