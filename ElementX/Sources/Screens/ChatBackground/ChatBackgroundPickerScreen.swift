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
    
    @ObservationIgnored private let store: ChatBackgroundStore
    
    init(roomID: String, store: ChatBackgroundStore) {
        self.roomID = roomID
        self.store = store
        selection = store.background(for: roomID)
    }
    
    func refresh() async {
        await store.refresh()
        if !isSaving {
            selection = store.background(for: roomID)
        }
    }
    
    func select(_ background: ChatBackground?) async {
        guard background != selection, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        if await store.setBackground(background, for: roomID) {
            selection = background
        } else {
            isShowingError = true
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
}

/// 2ecure: the sheet for choosing a chat's background: none, a photo or one of the gradients.
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
                    ListRow(label: .default(title: TwoEcureL10n.tr("chat_background_none"), icon: swatch(nil)),
                            kind: .selection(isSelected: model.selection == nil) {
                                Task { await model.select(nil) }
                            })
                    
                    ListRow(label: .default(title: TwoEcureL10n.tr("chat_background_photo"), icon: \.image),
                            kind: .selection(isSelected: isPhotoSelected) {
                                isPickingPhoto = true
                            })
                }
                
                Section {
                    ForEach(ChatBackgroundGradient.allCases) { gradient in
                        ListRow(label: .default(title: gradient.name, icon: swatch(gradient)),
                                kind: .selection(isSelected: model.selection == .gradient(gradient)) {
                                    Task { await model.select(.gradient(gradient)) }
                                })
                    }
                } header: {
                    Text(TwoEcureL10n.tr("chat_background_colours"))
                        .compoundListSectionHeader()
                } footer: {
                    Text(TwoEcureL10n.tr("chat_background_footer"))
                        .compoundListSectionFooter()
                }
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
    
    private var isPhotoSelected: Bool {
        if case .image = model.selection {
            true
        } else {
            false
        }
    }
    
    private func swatch(_ gradient: ChatBackgroundGradient?) -> some View {
        Circle()
            .fill(LinearGradient(colors: gradient?.colours(isDark: colorScheme == .dark) ?? [.compound.bgCanvasDefault],
                                 startPoint: .top,
                                 endPoint: .bottom))
            .overlay {
                Circle()
                    .stroke(Color.compound.borderInteractiveSecondary, lineWidth: 1)
            }
            .frame(width: 24, height: 24)
    }
    
    private func selectPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else {
            model.isShowingError = true
            return
        }
        await model.selectPhoto(data)
    }
}
