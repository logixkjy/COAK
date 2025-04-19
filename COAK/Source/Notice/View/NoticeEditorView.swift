//
//  NoticeEditorView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import ComposableArchitecture

struct NoticeEditorView: View {
    @Binding var notice: Notice
    var isNew: Bool = false
    let store: StoreOf<NoticesFeature>
    
    @Environment(\.dismiss) var dismiss

    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var errorMessage: String?
    @State private var isShowingImagePicker: Bool = false
    @State private var selectedImageData: Data? = nil

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case title
        case content
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                Form {
                    Section(header: Text("공지 제목")) {
                        TextField("공지 사항 제목 입력", text: $notice.title)
                            .focused($focusedField, equals: .title)
                    }
                    
                    Section(header: Text("공지 내용")) {
                        TextEditor(text: $notice.content)
                            .frame(height: 150)
                            .focused($focusedField, equals: .title)
                    }
                    
                    Section(header: Text("이미지")) {
                        if let data = selectedImageData, let uiImage = UIImage(data: data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                        } else if let url = notice.imageURL.flatMap({ URL(string: $0) }) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                        
                        Button("이미지 선택") {
                            isShowingImagePicker = true
                        }
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error).foregroundColor(.red)
                        }
                    }
                    
                    Section {
                        Button(action: submitNotice) {
                            if isSubmitting {
                                ProgressView()
                            } else {
                                Text(isNew ? "등록" : "수정")
                            }
                        }
                        .disabled(notice.title.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  notice.content.trimmingCharacters(in: .whitespaces).isEmpty ||
                                  isSubmitting)
                    }
                }
                .navigationTitle(isNew ? "공지사항 작성" : "공지사항 수정")
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
                .alert(isNew ? "공지 등록 완료!" : "공지 수정 완료!", isPresented: $showAlert) {
                    Button("확인", role: .cancel) {
                        viewStore.send(.onAppear)
                        dismiss()
                    }
                }
                .sheet(isPresented: $isShowingImagePicker) {
                    PhotoPicker(data: $selectedImageData)
                }
            }
        }
    }

    func submitNotice() {
        isSubmitting = true
        
        Task {
            do {
                var uploadedImageURL: String? = notice.imageURL

                // 새 이미지 선택된 경우 Firebase Storage 업로드
                if let imageData = selectedImageData {
                    let storageRef = Storage.storage().reference().child("notices/\(UUID().uuidString).jpg")
                    _ = try await storageRef.putDataAsync(imageData)
                    uploadedImageURL = try await storageRef.downloadURL().absoluteString
                }
                
                let db = Firestore.firestore()
                let data: [String: Any] = [
                    "title": notice.title,
                    "content": notice.content,
                    "imageURL": uploadedImageURL as Any,
                    "createdAt": notice.createdAt
                ]
                if let id = notice.id {
                    try await db.collection("notices").document(id).setData(data, merge: true)
                } else {
                    _ = try await db.collection("notices").addDocument(data: data)
                }
                dismiss()
            } catch {
                errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)"
            }
            
            isSubmitting = false
        }
    }
}

import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var data: Data?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else { return }

            provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
                DispatchQueue.main.async {
                    self.parent.data = data
                }
            }
        }
    }
}
