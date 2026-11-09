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
        case .customGradient(let top, let bottom):
            LinearGradient(colors: [top.color, bottom.color], startPoint: .top, endPoint: .bottom)
        case .colour(let colour):
            colour.color
        case .pattern(let pattern, let colour):
            ChatBackgroundPatternView(pattern: pattern, colour: colour)
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
                // A veil in the canvas colour calms busy photos behind the messages.
                Color.compound.bgCanvasDefault
                    .opacity(colorScheme == .dark ? 0.55 : 0.45)
            }
        case nil:
            EmptyView()
        }
    }
}

/// 2ecure: a pattern over its base colour; the geometry is shared with Android (docs/chat-backgrounds.md).
struct ChatBackgroundPatternView: View {
    let pattern: ChatBackgroundPattern
    let colour: ChatBackgroundColour
    /// Swatches draw the pattern smaller.
    var scale: CGFloat = 1
    
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(colour.color))
            context.scaleBy(x: scale, y: scale)
            let area = CGSize(width: size.width / scale, height: size.height / scale)
            draw(in: &context, area: area, motif: .color(colour.motif.color))
        }
    }
    
    private func draw(in context: inout GraphicsContext, area: CGSize, motif: GraphicsContext.Shading) {
        switch pattern {
        case .regal:
            for (x, y) in tiles(area, width: 40, height: 56) {
                var diamond = Path()
                diamond.move(to: CGPoint(x: x + 20, y: y))
                diamond.addLine(to: CGPoint(x: x + 40, y: y + 28))
                diamond.addLine(to: CGPoint(x: x + 20, y: y + 56))
                diamond.addLine(to: CGPoint(x: x, y: y + 28))
                diamond.closeSubpath()
                context.stroke(diamond, with: motif, lineWidth: 1.5)
                var dots = Path()
                for (dx, dy) in [(20.0, 22.0), (20, 34), (14, 28), (26, 28)] {
                    dots.addEllipse(in: circle(x + dx, y + dy, 2.2))
                }
                dots.addEllipse(in: circle(x + 20, y + 28, 1.6))
                for (dx, dy) in [(0.0, 0.0), (40, 0), (0, 56), (40, 56)] {
                    dots.addEllipse(in: circle(x + dx, y + dy, 3))
                }
                context.fill(dots, with: motif)
            }
        case .dots:
            var dots = Path()
            for (x, y) in tiles(area, width: 24, height: 24) {
                dots.addEllipse(in: circle(x + 6, y + 6, 3))
                dots.addEllipse(in: circle(x + 18, y + 18, 3))
            }
            context.fill(dots, with: motif)
        case .stripes:
            var stripes = Path()
            var offset = 0.0
            while offset <= area.width + area.height {
                stripes.move(to: CGPoint(x: offset, y: 0))
                stripes.addLine(to: CGPoint(x: offset - area.height, y: area.height))
                offset += 20
            }
            context.stroke(stripes, with: motif, lineWidth: 6)
        case .checks:
            var squares = Path()
            for (x, y) in tiles(area, width: 32, height: 32) {
                squares.addRect(CGRect(x: x, y: y, width: 16, height: 16))
                squares.addRect(CGRect(x: x + 16, y: y + 16, width: 16, height: 16))
            }
            context.fill(squares, with: motif)
        case .waves:
            var waves = Path()
            for y in stride(from: 0.0, through: area.height, by: 20) {
                waves.move(to: CGPoint(x: 0, y: y + 10))
                for x in stride(from: 0.0, through: area.width, by: 40) {
                    waves.addQuadCurve(to: CGPoint(x: x + 20, y: y + 10), control: CGPoint(x: x + 10, y: y + 2))
                    waves.addQuadCurve(to: CGPoint(x: x + 40, y: y + 10), control: CGPoint(x: x + 30, y: y + 18))
                }
            }
            context.stroke(waves, with: motif, lineWidth: 2)
        case .zigzag:
            var zigzag = Path()
            for y in stride(from: 0.0, through: area.height, by: 16) {
                zigzag.move(to: CGPoint(x: 0, y: y + 12))
                for x in stride(from: 0.0, through: area.width, by: 24) {
                    zigzag.addLine(to: CGPoint(x: x + 12, y: y + 4))
                    zigzag.addLine(to: CGPoint(x: x + 24, y: y + 12))
                }
            }
            context.stroke(zigzag, with: motif, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        case .stars:
            var stars = Path()
            for (x, y) in tiles(area, width: 48, height: 48) {
                addStar(to: &stars, centre: CGPoint(x: x + 12, y: y + 12))
                addStar(to: &stars, centre: CGPoint(x: x + 36, y: y + 36))
            }
            context.fill(stars, with: motif)
        }
    }
    
    private func tiles(_ area: CGSize, width: CGFloat, height: CGFloat) -> [(CGFloat, CGFloat)] {
        stride(from: 0.0, through: area.height, by: height).flatMap { y in
            stride(from: 0.0, through: area.width, by: width).map { x in (x, y) }
        }
    }
    
    private func circle(_ x: CGFloat, _ y: CGFloat, _ radius: CGFloat) -> CGRect {
        CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
    }
    
    private func addStar(to path: inout Path, centre: CGPoint) {
        let points = (0..<10).map { index in
            let radius: CGFloat = index.isMultiple(of: 2) ? 6 : 2.6
            let angle = -CGFloat.pi / 2 + CGFloat(index) * .pi / 5
            return CGPoint(x: centre.x + radius * cos(angle), y: centre.y + radius * sin(angle))
        }
        path.addLines(points)
        path.closeSubpath()
    }
}

/// 2ecure: a label in the canvas colour behind text the timeline draws straight on a chat background.
struct ChatBackgroundLabelModifier: ViewModifier {
    @Environment(\.hasChatBackground) private var hasChatBackground
    
    func body(content: Content) -> some View {
        if hasChatBackground {
            content
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.compound.bgCanvasDefault.opacity(0.9)))
        } else {
            content
        }
    }
}

extension View {
    /// 2ecure: see `ChatBackgroundLabelModifier`.
    func chatBackgroundLabel() -> some View {
        modifier(ChatBackgroundLabelModifier())
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
        ChatBackgroundView(background: .pattern(.regal, colour: .defaultPatternColour), mediaProvider: nil)
            .previewDisplayName("Regal")
        ChatBackgroundView(background: .customGradient(top: .defaultColour, bottom: .defaultGradientBottom), mediaProvider: nil)
            .preferredColorScheme(.dark)
            .previewDisplayName("Own gradient, dark")
    }
}
