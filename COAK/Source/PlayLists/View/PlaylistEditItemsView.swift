//
//  PlaylistEditItemsView.swift
//  COAK
//
//  Created by JooYoung Kim on 4/22/25.
//

import SwiftUI
import ComposableArchitecture

struct PlaylistEditItemsView: View {
    let store: StoreOf<PlaylistEditFeature>
    @State private var isPresentingAddSheet = false
    @State private var editingItem: PlaylistItemEdit?
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            let selectedGroup = viewStore.groups.first(where: { $0.id == viewStore.selectedGroupId })
            let items = selectedGroup?.playlists.sorted(by: { $0.order < $1.order }) ?? []
            
            List {
                ForEach(items) { item in
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
                        
                        Button(action: {
                            editingItem = item
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                }
                .onDelete { indexSet in
                    viewStore.send(.deleteItem(indexSet))
                }
                .onMove { indices, destination in
                    viewStore.send(.moveItem(indices, destination))
                }
            }
            .listStyle(.plain)
            .navigationTitle("그룹: \(selectedGroup?.title ?? "알 수 없음")")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresentingAddSheet = true
                    }) {
                        Label("추가", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                PlaylistItemEditFormView(
                    title: "",
                    playlistId: "",
                    isPremium: false,
                    onSave: { title, playlistIdUrl, isPremium in
                        let playlistId: String = {
                            if playlistIdUrl.hasPrefix("http") {
                                guard let playlistId = extractPlaylistId(from: playlistIdUrl) else {
                                    return ""
                                }
                                return playlistId
                            }
                            return playlistIdUrl
                        }()
                        viewStore.send(.addItem(title, playlistId, isPremium ? "true" : "false" ))
                        isPresentingAddSheet = false
                    },
                    onCancel: { isPresentingAddSheet = false }
                )
            }
            .sheet(item: $editingItem) { item in
                PlaylistItemEditFormView(
                    title: item.title,
                    playlistId: item.id,
                    isPremium: item.isPremiumRequired == "true",
                    onSave: { newTitle, newId, newIsPremium in
                        let playlistId: String = {
                            if newId.hasPrefix("http") {
                                guard let playlistId = extractPlaylistId(from: newId) else {
                                    return ""
                                }
                                return playlistId
                            }
                            return newId
                        }()
                        viewStore.send(.editItem(item.id, newTitle, playlistId, newIsPremium ? "true" : "false"))
                        editingItem = nil
                    },
                    onCancel: { editingItem = nil }
                )
            }
        }
    }
    
    private func extractPlaylistId(from urlString: String) -> String? {
        guard let components = URLComponents(string: urlString),
              let queryItems = components.queryItems else {
            return nil
        }
        return queryItems.first(where: { $0.name == "list" })?.value
    }
}
