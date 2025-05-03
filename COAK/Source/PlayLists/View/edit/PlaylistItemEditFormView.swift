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
                TextField("제목", text: $title)
                    .focused($focusedField, equals: .title)
                TextField("YouTube 재생목록 ID", text: $playlistId)
                    .focused($focusedField, equals: .id)
                Toggle("유료 전용", isOn: $isPremium)
            }
            .navigationTitle("재생목록 항목")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소", action: onCancel)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        onSave(title, playlistId, isPremium)
                    }
                    .disabled(title.isEmpty || playlistId.isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}
