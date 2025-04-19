//
//  PlaylistEditorView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import FirebaseFirestore

struct PlaylistEditorView: View {
    @Environment(\.dismiss) var dismiss

    @State private var playlistId: String = ""
    @State private var youtubeURLInput: String = ""
    @State private var customTitle: String = ""
    @State private var order: Int = 0
    @State private var isSubmitting = false
    @State private var showSuccess = false
    
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case id
        case title
        case order
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("YouTube 재생목록 주소")) {
                    TextField("예: https://www.youtube.com/playlist?list=...", text: $youtubeURLInput)
                        .focused($focusedField, equals: .id)
                        .autocapitalization(.none)
                        .onChange(of: youtubeURLInput) { newValue in
                            if let id = extractPlaylistId(from: newValue) {
                                playlistId = id
                            }
                        }
                }

                Section(header: Text("표시할 제목 (선택)")) {
                    TextField("예: 합창 제목", text: $customTitle)
                        .focused($focusedField, equals: .title)
                }

                Section(header: Text("표시 순서 (선택, 숫자)")) {
                    TextField("예: 1", value: $order, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .order)
                }

                Section {
                    Button(action: submit) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("등록하기")
                        }
                    }
                    .disabled(playlistId.trimmingCharacters(in: .whitespaces).isEmpty || isSubmitting)
                }
            }
            .navigationTitle("재생목록 등록")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                Task {
                    do {
                        order = try await fetchNextOrder()
                    } catch {
//                        errorMessage = "순서 불러오기 실패: \(error.localizedDescription)"
                    }
                }
            }
            .alert("등록 완료!", isPresented: $showSuccess) {
                Button("확인", role: .cancel) {
                    dismiss()
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true

        var data: [String: Any] = [
            "playlistId": playlistId,
            "createdAt": Timestamp(date: Date())
        ]

        if !customTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            data["customTitle"] = customTitle
        }

        data["order"] = order

        Firestore.firestore()
            .collection("playlists")
            .addDocument(data: data) { error in
                isSubmitting = false
                if error == nil {
                    showSuccess = true
                    playlistId = ""
                    customTitle = ""
                    order = 0
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
    
    private func fetchNextOrder() async throws -> Int {
        let snapshot = try await Firestore.firestore()
            .collection("playlists")
            .order(by: "order", descending: true)
            .limit(to: 1)
            .getDocuments()
        
        if let doc = snapshot.documents.first,
           let maxOrder = doc.data()["order"] as? Int {
            return maxOrder + 1
        } else {
            return 1
        }
    }
}
