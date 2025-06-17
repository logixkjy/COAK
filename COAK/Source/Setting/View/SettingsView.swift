//
//  SettingsView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

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
    let announcementStore: StoreOf<AnnouncementFeature>
    
    @State private var isShowingAnnouncementPost = false
    @State private var isShowingPlaylistEditor = false
    @State private var isShowingAdminPush = false
    @State private var isShowingUserList = false
    //    @State private var announcement: Announcement = Announcement(id: "", content: "", imageURLs: [], authorName: "", authorProfileImageURL: nil, createdAt: Date())
    @State private var showDeleteConfirm = false
    @State private var isShowingPolicy = false
    
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var birthDay: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var showSavedAlert = false
    @State private var showProfileEditor = false
    @State private var showImageViewer = false
    @State private var isNotshowImageViewer = false
    @State private var isPremium = false
    
    @State private var showImagePicker = false
    @State private var imagePickerSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var showImageSourceSheet = false
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            WithViewStore(appStore, observe: { $0 }) { appViewStore in
                NavigationView {
                    ZStack {
                        Color.black01.ignoresSafeArea()
                        
                        Form {
                            Section(header: Text("setting_my_info")
                                .font(.headline)) {
                                    HStack(alignment: .top) {
                                        ZStack(alignment: .bottomTrailing) {
                                            Button {
                                                showImageViewer = true
                                            } label: {
                                                if let image = profileImage {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .frame(width: 60, height: 60)
                                                        .clipShape(Circle())
                                                } else {
                                                    Image(systemName: "person.crop.circle")
                                                        .resizable()
                                                        .frame(width: 60, height: 60)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                            .contentShape(Circle())
                                            
                                            Button {
                                                showImageSourceSheet = true
                                            } label: {
                                                Image(systemName: "camera.circle.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.blue)
                                                    .background(Color.white.clipShape(Circle()))
                                                    .padding(4)
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .padding(.trailing)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("setting_email").bold()
                                                Text(email).foregroundColor(.gray)
                                            }
                                            HStack {
                                                Text("setting_name").bold()
                                                Text(name).foregroundColor(.gray)
                                            }
                                            HStack {
                                                Text("setting_phone").bold()
                                                Text(phone).foregroundColor(.gray)
                                            }
                                            HStack {
                                                Text("setting_birth").bold()
                                                Text(birthDay).foregroundColor(.gray)
                                            }
                                        }
                                    }
                                }
                            
                            
                            Section {
                                Button("setting_my_info_edit") {
                                    showProfileEditor = true
                                }
                                Button("setting_policy") {
                                    isShowingPolicy = true
                                }
                            }
                            
                            Section {
                                Button("setting_logout") {
                                    appViewStore.send(.logoutTapped)
                                }
                                .foregroundColor(.red)
                            }
                            
                            if let isAdmin = appViewStore.userProfile?.isAdmin, isAdmin == true {
                                Section(header: Text("setting_admin_info")) {
                                    Button("setting_notice_register") {
                                        isShowingAnnouncementPost = true
                                    }
                                    .foregroundColor(.white)
                                    
                                    Button("setting_user_list") {
                                        isShowingUserList = true
                                    }
                                    .foregroundColor(.white)
                                    
                                    Button("setting_play_list_edit") {
                                        isShowingPlaylistEditor = true
                                    }
                                    .foregroundColor(.white)
                                    
                                    Button("setting_push_send") {
                                        isShowingAdminPush = true
                                    }
                                    .foregroundColor(.white)
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                    .navigationTitle("main_setting")
                    .onAppear {
                        viewStore.send(.onAppear)
                        loadUserProfile(userProfile: appViewStore.userProfile)
                    }
                    .confirmationDialog("setting_profile_image_select", isPresented: $showImageSourceSheet) {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            Button("setting_profile_image_camera") {
                                imagePickerSource = .camera
                                showImagePicker = true
                            }
                        }
                        Button("setting_profile_image_album") {
                            imagePickerSource = .photoLibrary
                            showImagePicker = true
                        }
                        Button("common_cancel", role: .cancel) {}
                    }
                    .sheet(isPresented: $isShowingAnnouncementPost) {
                        AnnouncementPostView(store: announcementStore, appStore: appStore)
                    }
                    .sheet(isPresented: $isShowingPlaylistEditor) {
                        PlaylistEditGroupsView(store: appStore.scope(state: \.playlistEdit, action: AppFeature.Action.playlistEdit))
                    }
                    .sheet(isPresented: $isShowingAdminPush) {
                        AdminPushView(store: appStore.scope(state: \.adminPush, action: AppFeature.Action.adminPush))
                    }
                    .sheet(isPresented: $isShowingUserList) {
                        UserListView()
                    }
                    .sheet(isPresented: $isShowingPolicy) {
                        SafariWebView(url: URL(string: "https://logixkjy.github.io/coak-privacy-policy")!)
                    }
                    .sheet(isPresented: $showProfileEditor, onDismiss: {
                        loadUserProfile(userProfile: appViewStore.userProfile)
                    }) {
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
                    .alert("setting_image_save", isPresented: $showSavedAlert) {
                        Button("common_ok", role: .cancel) {}
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
            self.phone = userProfile.phone ?? ""
            self.birthDay = userProfile.birthdate?.formatted(date: .numeric, time: .omitted) ?? ""
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
            } else {
                Image(systemName: "person.crop.circle")
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
