//
// Copyright 2026 2ecure.
//
// SPDX-License-Identifier: AGPL-3.0-only.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// 2ecure: the question «Who can find you?» after signing in, shown until the account has chosen (docs/privacy.md).
@Observable
final class PrivacyChoiceModel {
    var selection: Bool?
    private(set) var isSaving = false
    var isShowingError = false
    
    @ObservationIgnored private let clientProxy: ClientProxyProtocol
    @ObservationIgnored private let onDone: () -> Void
    
    init(clientProxy: ClientProxyProtocol, onDone: @escaping () -> Void) {
        self.clientProxy = clientProxy
        self.onDone = onDone
    }
    
    func save() async {
        guard let selection, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }
        
        if await PrivacyChoice.setDiscoverable(selection, clientProxy: clientProxy) {
            onDone()
        } else {
            isShowingError = true
        }
    }
}

final class PrivacyChoiceScreenCoordinator: CoordinatorProtocol {
    private let model: PrivacyChoiceModel
    
    init(clientProxy: ClientProxyProtocol, onDone: @escaping () -> Void) {
        model = PrivacyChoiceModel(clientProxy: clientProxy, onDone: onDone)
    }
    
    func toPresentable() -> AnyView {
        AnyView(PrivacyChoiceScreen(model: model))
    }
}

struct PrivacyChoiceScreen: View {
    @Bindable var model: PrivacyChoiceModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PrivacyChoiceRows(selection: model.selection) { model.selection = $0 }
                } header: {
                    Text(TwoEcureL10n.tr("privacy_choice_message"))
                        .compoundListSectionHeader()
                } footer: {
                    Text(TwoEcureL10n.tr("privacy_choice_footer"))
                        .compoundListSectionFooter()
                }
            }
            .compoundList()
            .disabled(model.isSaving)
            .navigationTitle(TwoEcureL10n.tr("privacy_choice_title"))
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                Button {
                    Task { await model.save() }
                } label: {
                    if model.isSaving {
                        ProgressView()
                    } else {
                        Text(TwoEcureL10n.tr("privacy_choice_continue"))
                    }
                }
                .buttonStyle(.compound(.primary))
                .disabled(model.selection == nil || model.isSaving)
                .padding(16)
            }
            .alert(TwoEcureL10n.tr("privacy_choice_error"), isPresented: $model.isShowingError) {
                Button(L10n.actionOk) { }
            }
        }
        .interactiveDismissDisabled()
    }
}

/// The two choices, for the question after signing in and for the settings.
struct PrivacyChoiceRows: View {
    let selection: Bool?
    let select: (Bool) -> Void
    
    var body: some View {
        ListRow(label: .plain(title: TwoEcureL10n.tr("privacy_choice_everyone"),
                              description: TwoEcureL10n.tr("privacy_choice_everyone_description")),
                kind: .selection(isSelected: selection == true) { select(true) })
        ListRow(label: .plain(title: TwoEcureL10n.tr("privacy_choice_contacts"),
                              description: TwoEcureL10n.tr("privacy_choice_contacts_description")),
                kind: .selection(isSelected: selection == false) { select(false) })
    }
}
