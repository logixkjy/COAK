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
            
            ZStack {
                Color.black01.ignoresSafeArea()
                
                List {
                    ForEach(items) { item in
                        HStack {
                            Image(systemName: item.isPremiumRequired ? "lock.fill" : "lock.open")
                                .foregroundColor(item.isPremiumRequired ? .green : .gray)
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                Text("ID: \(item.id)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
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
                        .onTapGesture {
                            editingItem = item
                        }
                    }
                    .onDelete { indexSet in
                        viewStore.send(.deleteItem(indexSet))
                    }
                    .onMove { indices, destination in
                        viewStore.send(.moveItem(indices, destination))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("\(selectedGroup?.title ?? "common_notthing")")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        isPresentingAddSheet = true
                    }) {
                        Label("common_add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                PlaylistItemEditFormView(
                    title: "",
                    playlistId: "",
                    videoId: "",
                    isPremium: false,
                    onSave: { title, playlistIdUrl, videoId, isPremium in
                        let playlistId: String = {
                            if playlistIdUrl.hasPrefix("http") {
                                guard let playlistId = extractPlaylistId(from: playlistIdUrl) else {
                                    return ""
                                }
                                return playlistId
                            }
                            return playlistIdUrl
                        }()
                        viewStore.send(.addItem(title, playlistId, videoId, isPremium))
                        isPresentingAddSheet = false
                    },
                    onCancel: { isPresentingAddSheet = false }
                )
            }
            .sheet(item: $editingItem) { item in
                PlaylistItemEditFormView(
                    title: item.title,
                    playlistId: item.id,
                    videoId: item.videoId,
                    isPremium: item.isPremiumRequired,
                    onSave: { newTitle, newId, videoId, newIsPremium in
                        let playlistId: String = {
                            if newId.hasPrefix("http") {
                                guard let playlistId = extractPlaylistId(from: newId) else {
                                    return ""
                                }
                                return playlistId
                            }
                            return newId
                        }()
                        viewStore.send(.editItem(item.id, newTitle, playlistId, videoId, newIsPremium))
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
