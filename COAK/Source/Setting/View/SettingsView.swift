//
//  SettingsView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

// SettingsView.swift - 프로필 이미지 ActionSheet & Viewer 완성형

import SwiftUI
import ComposableArchitecture
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI
import WebKit

struct SettingsView: View {
    let store: StoreOf<SettingsFeature>
    let appStore: StoreOf<AppFeature>
    let noticesStore: StoreOf<NoticesFeature>

    @State private var isShowingNoticeEditor = false
    @State private var isShowingPlaylistEditor = false
    @State private var notice: Notice = Notice(title: "", content: "", createdAt: Date())
    @State private var showDeleteConfirm = false
    @State private var isShowingPolicy = false

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var showSavedAlert = false
    @State private var showProfileEditor = false
    @State private var showImageViewer = false
    @State private var isPremium = false

    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImageSourceSheet = false

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            WithViewStore(appStore, observe: { $0 }) { appViewStore in
                NavigationView {
                    Form {
                        Section(header: Text("내 정보")) {
                            HStack(alignment: .top) {
                                ZStack(alignment: .bottomTrailing) {
                                    Button {
                                        showImageViewer = true
                                    } label: {
                                        if let image = profileImage {
                                            Image(uiImage: image)
                                                .resizable()
                                                .frame(width: 80, height: 80)
                                                .clipShape(Circle())
                                        } else {
                                            Image(systemName: "person.crop.circle")
                                                .resizable()
                                                .frame(width: 80, height: 80)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .contentShape(Circle()) // ✅ 이미지 영역만 터치로 인식
                                    
                                    Button {
                                        showImageSourceSheet = true
                                    } label: {
                                        Image(systemName: "camera.circle.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.blue)
                                            .background(Color.white.clipShape(Circle()))
                                            .padding(4)
                                    }
                                    .contentShape(Rectangle()) // ✅ 버튼 내부 터치만 반응
                                }
                                .padding(.trailing)

                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("이메일:").bold()
                                        Text(email).foregroundColor(.gray)
                                    }
                                    HStack {
                                        Text("이름:").bold()
                                        Text(name).foregroundColor(.gray)
                                    }
                                }
                                .onTapGesture {
                                    showProfileEditor = true
                                }
                            }
                        }

                        Section {
                            Button("개인정보 처리방침 보기") {
                                isShowingPolicy = true
                            }
                            Button("회원 탈퇴") {
                                showDeleteConfirm = true
                            }
                            .foregroundColor(.red)
                        }

                        Section {
                            Button("로그아웃") {
                                appViewStore.send(.logoutTapped)
                            }
                            .foregroundColor(.red)
                        }

                        if appViewStore.isAdmin {
                            Section(header: Text("관리자 기능")) {
                                Button("공지 등록") {
                                    isShowingNoticeEditor = true
                                }
                                NavigationLink("전체 사용자 보기") {
                                    UserListView()
                                }
//                                Button("재생목록 등록") {
//                                    isShowingPlaylistEditor = true
//                                }
                            }
                        }
                    }
                    .navigationTitle("설정")
                    .onAppear {
                        viewStore.send(.onAppear)
                        loadUserProfile(userProfile: appViewStore.userProfile)
                    }
                    .confirmationDialog("프로필 이미지 선택", isPresented: $showImageSourceSheet) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button("사진 촬영") {
                                imagePickerSource = .camera
                                showImagePicker = true
                            }
                        }
                        Button("앨범에서 선택") {
                            imagePickerSource = .photoLibrary
                            showImagePicker = true
                        }
                        Button("취소", role: .cancel) {}
                    }
                    .sheet(isPresented: $isShowingNoticeEditor) {
                        NoticeEditorView(notice: $notice, isNew: true, store: noticesStore)
                    }
                    .sheet(isPresented: $isShowingPlaylistEditor) {
                        PlaylistEditorView()
                    }
                    .sheet(isPresented: $isShowingPolicy) {
                        SafariWebView(url: URL(string: "https://logixkjy.github.io/privacy.html")!)
                    }
                    .sheet(isPresented: $showProfileEditor) {
                        ProfileUpdateView(store: appStore)
                    }
                    .fullScreenCover(isPresented: $showImageViewer) {
                        ImageViewerView(image: profileImage)
                    }
                    .fullScreenCover(isPresented: $showImagePicker) {
                        ImagePickerView(sourceType: imagePickerSource == .camera ? .camera : .photoLibrary) { image in
                            if let image = image {
                                self.profileImage = image
                                saveUserProfile()
                            }
                            showImagePicker = false
                        }
                    }
                    .alert("정말 탈퇴하시겠습니까?", isPresented: $showDeleteConfirm) {
                        Button("탈퇴", role: .destructive) {
                            deleteAccount()
                        }
                        Button("취소", role: .cancel) {}
                    } message: {
                        Text("이 작업은 되돌릴 수 없습니다.")
                    }
                    .alert("저장 완료", isPresented: $showSavedAlert) {
                        Button("확인", role: .cancel) {}
                    }
                }
            }
        }
    }

    func loadUserProfile(userProfile: UserProfile?) {
        if let userProfile = userProfile {
            if let urlString = userProfile.profileImageURL {
                if let url = URL(string: urlString) {
                    Task {
                        if let imageData = try? Data(contentsOf: url),
                           let image = UIImage(data: imageData) {
                            self.profileImage = image
                        }
                    }
                }
            }
            self.name = userProfile.name ?? ""
            self.email = userProfile.email ?? ""
            self.isPremium = userProfile.isPremium ?? false
        }
    }

    func saveUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Task {
            var imageURL: URL? = nil

            if let image = profileImage,
               let data = image.jpegData(compressionQuality: 0.8) {
                let ref = Storage.storage().reference().child("users/\(uid)/profile.jpg")
                do {
                    _ = try await ref.putDataAsync(data, metadata: nil)
                    imageURL = try await ref.downloadURL()
                } catch {
                    print("이미지 업로드 실패: \(error.localizedDescription)")
                }
            }

            var userData: [String: Any] = [:]
            if let imageURL {
                userData["profileImageURL"] = imageURL.absoluteString
//                self.appStore.userProfile?.profileImageURL = imageURL.absoluteString
            }
            
            do {
                try await Firestore.firestore()
                    .collection("users")
                    .document(uid)
                    .setData(userData, merge: true)
                showSavedAlert = true
            } catch {
                print("사용자 정보 저장 실패: \(error.localizedDescription)")
            }
        }
    }

    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        user.delete { error in
            if let error = error {
                print("회원탈퇴 실패: \(error.localizedDescription)")
                return
            }
            Firestore.firestore().collection("users").document(uid).delete { err in
                if let err = err {
                    print("유저 문서 삭제 실패: \(err.localizedDescription)")
                } else {
                    print("회원 탈퇴 및 유저 문서 삭제 완료")
                }
            }
        }
    }
}

struct ImageViewerView: View {
    let image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .overlay(
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        )
    }
}
