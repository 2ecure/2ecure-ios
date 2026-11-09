//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// 2ecure: draws a chat's background (`ChatBackground`) behind its timeline.
struct ChatBackgroundView: View {
    let background: ChatBackground?
    let mediaProvider: MediaProviderProtocol?
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            Color.compound.bgCanvasDefault
            content
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var content: some View {
        switch background {
        case .gradient(let gradient):
            LinearGradient(colors: gradient.colours(isDark: colorScheme == .dark), startPoint: .top, endPoint: .bottom)
        case .image(let url, let mimeType):
            if let url = URL(string: url), let mediaSource = try? MediaSourceProxy(url: url, mimeType: mimeType) {
                Color.clear
                    .overlay {
                        LoadableImage(mediaSource: mediaSource, mediaProvider: mediaProvider) { image in
                            image.scaledToFill()
                        } placeholder: {
                            Color.clear
                        }
                    }
                    .clipped()
                // A veil in the canvas colour keeps what is drawn straight on the background (dates, «X joined») readable.
                Color.compound.bgCanvasDefault
                    .opacity(colorScheme == .dark ? 0.55 : 0.45)
            }
        case nil:
            EmptyView()
        }
    }
}

extension EnvironmentValues {
    /// 2ecure: whether the timeline is drawn over a `ChatBackgroundView`, so it must not paint its own background.
    @Entry var hasChatBackground = false
}

struct ChatBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        ChatBackgroundView(background: .gradient(.sky), mediaProvider: nil)
            .previewDisplayName("Sky")
        ChatBackgroundView(background: .gradient(.rose), mediaProvider: nil)
            .preferredColorScheme(.dark)
            .previewDisplayName("Rose, dark")
    }
}
