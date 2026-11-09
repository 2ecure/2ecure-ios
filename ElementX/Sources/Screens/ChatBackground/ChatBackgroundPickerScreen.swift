//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import PhotosUI
import SwiftUI

/// 2ecure: the state of the chat settings' sheet for choosing a chat's background.
@Observable
final class ChatBackgroundPickerModel: Identifiable {
    let roomID: String
    private(set) var selection: ChatBackground?
    private(set) var isSaving = false
    var isShowingError = false
    
    /// The colours in the colour pickers; a change is saved shortly after the last one.
    var colour: Color
    var gradientTop: Color
    var gradientBottom: Color
    var patternColour: Color
    
    @ObservationIgnored private let store: ChatBackgroundStore
    @ObservationIgnored private var pendingSelection: Task<Void, Never>?
    
    init(roomID: String, store: ChatBackgroundStore) {
        self.roomID = roomID
        self.store = store
        colour = ChatBackgroundColour.defaultColour.color
        gradientTop = ChatBackgroundColour.defaultColour.color
        gradientBottom = ChatBackgroundColour.defaultGradientBottom.color
        patternColour = ChatBackgroundColour.defaultPatternColour.color
        showSelection(store.background(for: roomID))
    }
    
    func refresh() async {
        await store.refresh()
        if !isSaving, pendingSelection == nil {
            showSelection(store.background(for: roomID))
        }
    }
    
    func select(_ background: ChatBackground?) async {
        pendingSelection?.cancel()
        pendingSelection = nil
        guard background != selection, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        if await store.setBackground(background, for: roomID) {
            selection = background
        } else {
            isShowingError = true
        }
    }
    
    /// Saves a background chosen with a colour picker once the picker has been still for a moment.
    func selectSoon(_ background: ChatBackground) {
        guard background != selection else { return }
        pendingSelection?.cancel()
        pendingSelection = Task {
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            pendingSelection = nil
            await select(background)
        }
    }
    
    func selectPhoto(_ data: Data) async {
        guard !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        guard let background = await store.uploadPhoto(data), await store.setBackground(background, for: roomID) else {
            isShowingError = true
            return
        }
        selection = background
    }
    
    private func showSelection(_ background: ChatBackground?) {
        selection = background
        switch background {
        case .colour(let chosen):
            colour = chosen.color
        case .customGradient(let top, let bottom):
            gradientTop = top.color
            gradientBottom = bottom.color
        case .pattern(_, let chosen):
            patternColour = chosen.color
        case .gradient, .image, nil:
            break
        }
    }
}

/// 2ecure: the sheet for choosing a chat's background: none, a photo, a colour, a gradient or a pattern.
struct ChatBackgroundPickerScreen: View {
    @Bindable var model: ChatBackgroundPickerModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPickingPhoto = false
    @State private var photoItem: PhotosPickerItem?
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ListRow(label: .default(title: TwoEcureL10n.tr("chat_background_none"),
                                            icon: Swatch(fill: AnyShapeStyle(Color.compound.bgCanvasDefault))),
                            kind: .selection(isSelected: model.selection == nil) {
                                Task { await model.select(nil) }
                            })
                    
                    ListRow(label: .default(title: TwoEcureL10n.tr("chat_background_photo"), icon: \.image),
                            kind: .selection(isSelected: isPhotoSelected) {
                                isPickingPhoto = true
                            })
                }
                
                colourSection
                gradientSection
                patternSection
            }
            .compoundList()
            .disabled(model.isSaving)
            .overlay {
                if model.isSaving {
                    ProgressView()
                }
            }
            .navigationTitle(TwoEcureL10n.tr("chat_background_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.actionDone) {
                        dismiss()
                    }
                }
            }
            .photosPicker(isPresented: $isPickingPhoto, selection: $photoItem, matching: .images, photoLibrary: .shared())
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                photoItem = nil
                // Not tied to the view: the upload goes on when the sheet is closed.
                Task { await selectPhoto(item) }
            }
            .alert(TwoEcureL10n.tr("chat_background_error"), isPresented: $model.isShowingError) {
                Button(L10n.actionOk) { }
            }
            .task {
                await model.refresh()
            }
        }
    }
    
    private var colourSection: some View {
        Section {
            ListRow(label: .default(title: TwoEcureL10n.tr("chat_background_your_colour"),
                                    icon: Swatch(fill: AnyShapeStyle(model.colour))),
                    kind: .selection(isSelected: isColourSelected) {
                        Task { await model.select(.colour(ChatBackgroundColour(model.colour))) }
                    })
            colourPicker(TwoEcureL10n.tr("chat_background_change_colour"), selection: $model.colour)
                .onChange(of: model.colour) { _, colour in
                    model.selectSoon(.colour(ChatBackgroundColour(colour)))
                }
        } header: {
            Text(TwoEcureL10n.tr("chat_background_colour_section"))
                .compoundListSectionHeader()
        }
    }
    
    private var gradientSection: some View {
        Section {
            ForEach(ChatBackgroundGradient.allCases) { gradient in
                ListRow(label: .default(title: gradient.name,
                                        icon: Swatch(fill: AnyShapeStyle(LinearGradient(colors: gradient.colours(isDark: colorScheme == .dark),
                                                                                        startPoint: .top,
                                                                                        endPoint: .bottom)))),
                        kind: .selection(isSelected: model.selection == .gradient(gradient)) {
                            Task { await model.select(.gradient(gradient)) }
                        })
            }
            
            ListRow(label: .default(title: TwoEcureL10n.tr("chat_background_your_gradient"),
                                    icon: Swatch(fill: AnyShapeStyle(LinearGradient(colors: [model.gradientTop, model.gradientBottom],
                                                                                    startPoint: .top,
                                                                                    endPoint: .bottom)))),
                    kind: .selection(isSelected: isCustomGradientSelected) {
                        Task { await model.select(customGradient) }
                    })
            colourPicker(TwoEcureL10n.tr("chat_background_top_colour"), selection: $model.gradientTop)
                .onChange(of: model.gradientTop) {
                    model.selectSoon(customGradient)
                }
            colourPicker(TwoEcureL10n.tr("chat_background_bottom_colour"), selection: $model.gradientBottom)
                .onChange(of: model.gradientBottom) {
                    model.selectSoon(customGradient)
                }
        } header: {
            Text(TwoEcureL10n.tr("chat_background_gradients"))
                .compoundListSectionHeader()
        }
    }
    
    private var patternSection: some View {
        Section {
            colourPicker(TwoEcureL10n.tr("chat_background_pattern_colour"), selection: $model.patternColour)
                .onChange(of: model.patternColour) { _, colour in
                    if case .pattern(let pattern, _) = model.selection {
                        model.selectSoon(.pattern(pattern, colour: ChatBackgroundColour(colour)))
                    }
                }
            
            ForEach(ChatBackgroundPattern.allCases) { pattern in
                let background = ChatBackground.pattern(pattern, colour: ChatBackgroundColour(model.patternColour))
                ListRow(label: .default(title: pattern.name, icon: PatternSwatch(pattern: pattern, colour: ChatBackgroundColour(model.patternColour))),
                        kind: .selection(isSelected: isPatternSelected(pattern)) {
                            Task { await model.select(background) }
                        })
            }
        } header: {
            Text(TwoEcureL10n.tr("chat_background_patterns"))
                .compoundListSectionHeader()
        } footer: {
            Text(TwoEcureL10n.tr("chat_background_footer"))
                .compoundListSectionFooter()
        }
    }
    
    private func colourPicker(_ title: String, selection: Binding<Color>) -> some View {
        ColorPicker(selection: selection, supportsOpacity: false) {
            Text(title)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
        }
    }
    
    private var customGradient: ChatBackground {
        .customGradient(top: ChatBackgroundColour(model.gradientTop), bottom: ChatBackgroundColour(model.gradientBottom))
    }
    
    private var isPhotoSelected: Bool {
        if case .image = model.selection { true } else { false }
    }
    
    private var isColourSelected: Bool {
        if case .colour = model.selection { true } else { false }
    }
    
    private var isCustomGradientSelected: Bool {
        if case .customGradient = model.selection { true } else { false }
    }
    
    private func isPatternSelected(_ pattern: ChatBackgroundPattern) -> Bool {
        if case .pattern(pattern, _) = model.selection { true } else { false }
    }
    
    private func selectPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            model.isShowingError = true
            return
        }
        await model.selectPhoto(data)
    }
}

/// A round swatch that fills the list row's icon frame.
private struct Swatch: View {
    let fill: AnyShapeStyle
    
    var body: some View {
        Circle()
            .fill(fill)
            .overlay {
                Circle()
                    .strokeBorder(Color.compound.borderInteractiveSecondary, lineWidth: 1)
            }
            .padding(2)
    }
}

private struct PatternSwatch: View {
    let pattern: ChatBackgroundPattern
    let colour: ChatBackgroundColour
    
    var body: some View {
        ChatBackgroundPatternView(pattern: pattern, colour: colour, scale: 0.5)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .strokeBorder(Color.compound.borderInteractiveSecondary, lineWidth: 1)
            }
            .padding(2)
    }
}
