//
//  PlaylistItemEditFormView.swift
//  COAK
//
//  Created by JooYoung Kim on 4/24/25.
//

import SwiftUI

struct PlaylistItemEditFormView: View {
    @State var title: String
    @State var playlistId: String
    @State var isPremium: Bool
    
    @State var isShowErrorPopup: Bool = false
    @State var errorMessage: String = ""
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case title
        case id
    }
    
    var onSave: (String, String, Bool) -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("play_list_sub_edit_popup_title_hint", text: $title)
                    .focused($focusedField, equals: .title)
                TextField("play_list_sub_edit_popup_youtube_hint", text: $playlistId)
                    .focused($focusedField, equals: .id)
                Toggle("play_list_sub_edit_popup_paid", isOn: $isPremium)
            }
            .navigationTitle("play_list_sub_edit_popup_title")
            .alert(errorMessage, isPresented: $isShowErrorPopup) {
                Button("common_ok", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common_cancel", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("common_save") {
                        if title.isEmpty {
                            isShowErrorPopup.toggle()
                            errorMessage = NSLocalizedString("play_list_sub_edit_popup_title_error", comment: "")
                        } else if playlistId.isEmpty {
                            isShowErrorPopup.toggle()
                            errorMessage = NSLocalizedString("play_list_sub_edit_popup_youtube_error", comment: "")
                        } else {
                            onSave(title, playlistId, isPremium)
                        }
                    }
                    .disabled(title.isEmpty || playlistId.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common_close") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}
