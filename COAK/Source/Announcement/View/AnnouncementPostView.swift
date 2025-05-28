//
//  AnnouncementPostView.swift
//  COAK
//
//  Created by JooYoung Kim on 5/5/25.
//

import SwiftUI
import PhotosUI
import ComposableArchitecture
import FirebaseStorage


struct AnnouncementPostView: View {
    let store: StoreOf<AnnouncementFeature>
    let appStore: StoreOf<AppFeature>
    
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    @State private var selectedImages: [UIImage] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isUploading = false
    @State private var toastMessage: String? = nil
    
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
                    // 차후 3장 정도 까지 확장 가능
                    if selectedImages.count < 1 {
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

                    if !selectedImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
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
                    }

                    Button(action: uploadAnnouncement) {
                        HStack {
                            if isUploading {
                                ProgressView()
                            } else {
                                Image(systemName: "paperplane")
                                Text("notice_add_title")
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
            .navigationTitle("notice_add_title")
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

    private func uploadAnnouncement() {
        Task {
            isUploading = true
            do {
                var uploadedURLs: [String] = []
                var uploadedFileNames: [String] = []

                for image in selectedImages {
                    let resizedImage = resizeImage(image, toMinLength: 500)
                    let imageData = resizedImage.jpegData(compressionQuality: 0.8)!
                    let fileName = UUID().uuidString + ".jpg"
                    let ref = Storage.storage().reference().child("notices/\(fileName)")
                    let _ = try await ref.putDataAsync(imageData, metadata: nil)
                    let url = try await ref.downloadURL()
                    uploadedURLs.append(url.absoluteString)
                    uploadedFileNames.append(fileName)
                }

                let announcement = Announcement(
                    id: "",
                    content: content,
                    imageURLs: uploadedURLs,
                    imageFileNames: uploadedFileNames,
                    email: appStore.userProfile?.email ?? "",
                    userId: appStore.userProfile?.uid ?? "",
                    createdAt: Date()
                )
                
                store.send(.create(announcement))
                content = ""
                selectedImages = []
                selectedItems = []
                dismiss()
            } catch {
                showToast(message: "공지사항 등록에 실패했습니다.")
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
