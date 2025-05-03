//
//  PlaylistEditGroupsView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import ComposableArchitecture
    
struct PlaylistEditGroupsView: View {
    let store: StoreOf<PlaylistEditFeature>
    @State private var path = NavigationPath()
    @State private var isShowingAddAlert = false
    @State private var newGroupTitle = ""
    @State private var editingGroup: PlaylistGroupEdit? = nil
    @State private var editedGroupTitle = ""
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case name
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack(path: $path) {
                List {
                    ForEach(viewStore.groups.sorted(by: { $0.order < $1.order })) { group in
                        Button {
                            // 선택된 그룹 ID 설정
                            viewStore.send(.selectGroup(group.id))
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
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Divider()
                                
                                Text("playlit Count: \(group.playlists.count)")
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
                        viewStore.send(.deleteGroup(indexSet))
                    }
                    .onMove { indices, destination in
                        viewStore.send(.moveGroup(indices, destination))
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
                    ToolbarItem(placement: .bottomBar) {
                        Button("저장") {
                            viewStore.send(.saveTapped)
                        }
                    }
                }
                .onAppear {
                    viewStore.send(.onAppear)
                }
                // 그룹 추가 Alert
                .alert("새 그룹 추가", isPresented: $isShowingAddAlert, actions: {
                    TextField("그룹명", text: $newGroupTitle)
                        .focused($focusedField, equals: .name)
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
                        .focused($focusedField, equals: .name)
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
                    PlaylistEditItemsView(store: store)
                }
                .toolbar {
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
}
