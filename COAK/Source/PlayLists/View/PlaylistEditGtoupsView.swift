//
//  PlaylistEditGtoupsView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture
    
struct PlaylistEditGtoupsView: View {
    let store: StoreOf<PlaylistEditFeature>
    @State private var path = NavigationPath()
    @State private var isShowingAddAlert = false
    @State private var newGroupTitle = ""
    @State private var editingGroup: PlaylistGroupEdit? = nil
    @State private var editedGroupTitle = ""
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack(path: $path) {
                List {
                    ForEach(viewStore.groups.sorted(by: { $0.order < $1.order })) { group in
                        Button {
                            path.append(group)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(group.title)
                                        .font(.title2)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Button(action: {
                                        editingGroup = group
                                        editedGroupTitle = group.title
                                    }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Divider()
                                
                                Text("Order: \(group.order)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .onDelete { indexSet in
                        viewStore.send(.delete(indexSet))
                    }
                    .onMove { indices, destination in
                        viewStore.send(.move(indices, destination))
                    }
                }
                .listStyle(.plain)
                .navigationTitle("재생목록 그룹 수정")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            isShowingAddAlert = true
                        }) {
                            Label("그룹 추가", systemImage: "plus")
                        }
                    }

                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                            .foregroundColor(.blue)
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                // 그룹 추가 Alert
                .alert("새 그룹 추가", isPresented: $isShowingAddAlert, actions: {
                    TextField("그룹명", text: $newGroupTitle)
                    Button("추가", action: {
                        guard !newGroupTitle.isEmpty else { return }
                        viewStore.send(.addGroup(newGroupTitle))
                        newGroupTitle = ""
                    })
                    Button("취소", role: .cancel) {
                        newGroupTitle = ""
                    }
                })
                
                // 그룹 이름 수정 Alert
                .alert("그룹명 수정", isPresented: Binding(
                    get: { editingGroup != nil },
                    set: { if !$0 { editingGroup = nil }}
                ), actions: {
                    TextField("그룹명", text: $editedGroupTitle)
                    Button("저장", action: {
                        if let group = editingGroup {
                            viewStore.send(.editGroup(group.id, editedGroupTitle))
                        }
                        editingGroup = nil
                    })
                    Button("취소", role: .cancel) {
                        editingGroup = nil
                    }
                })
                
                .navigationDestination(for: PlaylistGroupEdit.self) { group in
                    PlaylistEditItemsView(group: group)
                }
            }
        }
    }
}
