//
//  PlaylistEditItemsView.swift
//  COAK
//
//  Created by JooYoung Kim on 4/22/25.
//

import SwiftUI
import ComposableArchitecture

struct PlaylistEditItemsView: View {
    let group: PlaylistGroupEdit
    @State private var newItemTitle = ""
    @State private var newItemPlaylistId = ""
    @State private var isPremium = false
    @State private var isShowingAddAlert = false
    @State private var editingItem: PlaylistItemEdit?
    @State private var editedTitle = ""
    @State private var editedPlaylistId = ""
    @State private var editedIsPremium = false
    
    var body: some View {
        WithViewStore(Store(
            initialState: PlaylistEditItemFeature.State(group: group),
            reducer: { PlaylistEditItemFeature() }
        ), observe: { $0 }) { viewStore in
            List {
                ForEach(viewStore.items.sorted(by: { $0.order < $1.order })) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.headline)
                            Text("ID: \(item.id)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle(isOn: Binding(
                            get: { item.isPremiumRequired == "true" },
                            set: { newValue in
                                viewStore.send(.setPremium(item.id, newValue))
                            }
                        )) {
                            Text("유료")
                        }
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .onDelete { indexSet in
                    viewStore.send(.delete(indexSet))
                }
                .onMove { indices, destination in
                    viewStore.send(.move(indices, destination))
                }
            }
            .listStyle(.plain)
            .navigationTitle("그룹: \(group.title)")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isShowingAddAlert = true
                    }) {
                        Label("추가", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton().foregroundColor(.blue)
                }
            }
            .alert("항목 추가", isPresented: $isShowingAddAlert) {
                VStack {
                    TextField("타이틀", text: $newItemTitle)
                    TextField("재생목록 ID", text: $newItemPlaylistId)
                    Button("추가") {
                        guard !newItemTitle.isEmpty && !newItemPlaylistId.isEmpty else { return }
                        viewStore.send(.addItem(newItemTitle, newItemPlaylistId))
                        newItemTitle = ""
                        newItemPlaylistId = ""
                        isPremium = false
                    }
                    Button("취소", role: .cancel) {
                        newItemTitle = ""
                        newItemPlaylistId = ""
                        isPremium = false
                    }
                }
            }
            .alert("항목 수정", isPresented: Binding(
                get: { editingItem != nil },
                set: { if !$0 { editingItem = nil } }
            )) {
                VStack {
                    TextField("타이틀", text: $editedTitle)
                    TextField("재생목록 ID", text: $editedPlaylistId)
                    Button("저장") {
                        if let item = editingItem {
                            viewStore.send(.editItem(item.id, editedTitle, editedPlaylistId))
                        }
                        editingItem = nil
                    }
                    Button("취소", role: .cancel) {
                        editingItem = nil
                    }
                }
            }
        }
    }
}
