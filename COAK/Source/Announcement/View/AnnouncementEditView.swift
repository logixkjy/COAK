//
//  AnnouncementEditView.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture
import FirebaseStorage

struct AnnouncementEditView: View {
    let store: StoreOf<AnnouncementFeature>
    let appStore: StoreOf<AppFeature>
    @Binding var announcement: Announcement
    @Binding var isEdited: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var toastMessage: String? = nil
    @State private var deleteImageIndexes: [Int] = []
//    @State private var updatedImages: [Int: UIImage] = [:]

    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case content
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("notice_edit_contents_hint")
                        .font(.headline)
                    
                    TextEditor(text: $content)
                        .frame(height: 150)
                        .padding(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))
                        .focused($focusedField, equals: .content)
                    
                    Text("notice_edit_image_select")
                        .font(.headline)
                    if announcement.imageURLs.count - deleteImageIndexes.count + selectedImages.count < 1 {
                        PhotosPicker(selection: $selectedItems,
                                     maxSelectionCount: 1,
                                     matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("notice_edit_image_select_count")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                                     .onChange(of: selectedItems) { newItems in
                                         Task {
                                             selectedImages = []
                                             for item in newItems.prefix(3) {
                                                 if let data = try? await item.loadTransferable(type: Data.self),
                                                    let uiImage = UIImage(data: data) {
                                                     selectedImages.append(uiImage)
                                                 }
                                             }
                                             focusedField = nil
                                         }
                                     }
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(announcement.imageURLs.enumerated()), id: \.offset) { index, urlString in
                                if !deleteImageIndexes.contains(index) {
                                    ZStack(alignment: .topTrailing) {
                                        AsyncImage(url: URL(string: urlString)) { image in
                                            image.resizable().scaledToFill().frame(width: 100, height: 100).clipped().cornerRadius(8)
                                        } placeholder: {
                                            Color.gray.frame(width: 100, height: 100)
                                        }

                                        Button(action: {
                                            deleteImageIndexes.append(index)
                                            focusedField = nil
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white)
                                                .clipShape(Circle())
                                                .padding(4)
                                        }
                                    }
                                }
                            }
                            // 이미지를 삭제하고 추가하는 경우에도 정상 표시
                            ForEach(selectedImages, id: \.self) { image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(8)
                                    Button(action: {
                                        if let index = selectedImages.firstIndex(of: image) {
                                            selectedImages.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                            .padding(4)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button(action: updateAnnouncement) {
                        HStack {
                            if isUploading {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane")
                                Text("notice_edit_title2")
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(content.isEmpty || isUploading)
                }
                .padding()
            }
            .navigationTitle("notice_edit_title2")
            .onAppear {
                self.content = announcement.content
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common_close") {
                        focusedField = nil
                    }
                }
            }
            .overlay(
                Group {
                    if let message = toastMessage {
                        VStack {
                            Spacer()
                            Text(message)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.bottom, 40)
                        }
                        .animation(.easeInOut, value: toastMessage)
                        .transition(.move(edge: .bottom))
                    }
                }
            )
        }
    }
    
    private func updateAnnouncement() {
        Task {
            isUploading = true
            do {
                var uploadedURLs: [String] = announcement.imageURLs
                var uploadedFileNames: [String] = announcement.imageFileNames
                
                // 삭제 처리
                for index in deleteImageIndexes {
                    let fileName = uploadedFileNames[index]
                    let ref = Storage.storage().reference().child("notices/\(fileName)")
                    try await ref.delete()
                    uploadedURLs.remove(at: index)
                    uploadedFileNames.remove(at: index)
                }
                
                // 수정 처리
                for image in selectedImages {
                    let resizedImage = resizeImage(image, toMinLength: 500)
                    let fileName = UUID().uuidString + ".jpg"
                    let ref = Storage.storage().reference().child("notices/\(fileName)")
                    let imageData = resizedImage.jpegData(compressionQuality: 0.8)!
                    let _ = try await ref.putDataAsync(imageData, metadata: nil)
                    let url = try await ref.downloadURL()
                    uploadedURLs.append(url.absoluteString)
                    uploadedFileNames.append(fileName)
                }
               
                announcement.content = content
                announcement.imageURLs = uploadedURLs
                announcement.imageFileNames = uploadedFileNames
                announcement.email = appStore.userProfile?.email ?? ""
                
                store.send(.update(announcement))
                content = ""
                selectedImages = []
                selectedItems = []
                showToast(message: "공지 수정 완료")
                isEdited.toggle()
                dismiss()
            } catch {
                showToast(message: "공지 수정 실패")
            }
            isUploading = false
        }
    }
    
    private func resizeImage(_ image: UIImage, toMinLength minLength: CGFloat) -> UIImage {
        let size = image.size
        let scale = minLength / min(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? image
    }
    
    private func showToast(message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            toastMessage = nil
        }
    }
}
