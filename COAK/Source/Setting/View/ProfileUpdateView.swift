// ProfileUpdateView.swift - 기존 정보 로딩 포함 + 전화번호 포맷

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import ComposableArchitecture

struct ProfileUpdateView: View {
    let store: StoreOf<AppFeature>
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteConfirm = false

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name
        case phone
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black01.ignoresSafeArea()
                
                VStack(spacing: 16) {
                    Text("join_name_hint")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading, .trailing], 8)
                    
                    TextField("join_name_hint", text: $name)
                        .textFieldStyleCustom()
                        .focused($focusedField, equals: .name)
                        .foregroundColor(.white)
                        .padding([.leading, .trailing], 8)
                    
                    HStack {
                        Spacer()
                        Text("\(name.count)/20")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.trailing, 16)
                    }
                    .padding([.leading, .trailing], 8)
                    
                    Text("join_phone_hint")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.leading, .trailing], 8)
                    
                    TextField("join_phone_hint", text: $phone)
                        .textFieldStyleCustom()
                        .focused($focusedField, equals: .phone)
                        .foregroundColor(.white)
                        .padding([.leading, .trailing], 8)
                    
                    HStack {
                        Text("join_phone_helper")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.trailing, 16)
                        Spacer()
                        Text("\(phone.count)/11")
                            .font(.footnote)
                            .foregroundColor(.white)
                            .padding(.trailing, 16)
                    }
                    .padding([.leading, .trailing], 8)
                    
                    DatePicker("join_birthday_title", selection: $birthdate, displayedComponents: .date)
                        .padding(.top, 16)
                        .padding([.leading, .trailing], 8)
                    
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("user_edit_button")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.top, 16)
                    
                    Button("setting_secession_popup_title") {
                        showDeleteConfirm = true
                    }
                    .foregroundColor(.red)
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
            .navigationTitle("user_edit_title")
            .onAppear {
                loadUserProfile()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common_close") {
                        focusedField = nil
                    }
                }
            }
            .alert("setting_secession_popup_message", isPresented: $showDeleteConfirm) {
                Button("setting_secession_popup_title", role: .destructive) {
                    deleteAccount()
                }
                Button("common_cancel", role: .cancel) {}
            } message: {
                Text("setting_secession_popup_desc")
            }
        }
    }

    func formatPhoneNumber(_ input: String) -> String {
        let digits = input.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if digits.count <= 3 {
            return digits
        } else if digits.count <= 7 {
            let prefix = String(digits.prefix(3))
            let mid = String(digits.suffix(from: digits.index(digits.startIndex, offsetBy: 3)))
            return "\(prefix)-\(mid)"
        } else if digits.count <= 11 {
            let prefix = String(digits.prefix(3))
            let midStart = digits.index(digits.startIndex, offsetBy: 3)
            let midEnd = digits.index(digits.startIndex, offsetBy: 7)
            let mid = String(digits[midStart..<midEnd])
            let suffix = String(digits.suffix(from: midEnd))
            return "\(prefix)-\(mid)-\(suffix)"
        } else {
            return input
        }
    }

    func loadUserProfile() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(uid).getDocument { snapshot, _ in
            guard let data = snapshot?.data() else { return }
            self.name = data["name"] as? String ?? ""
            self.phone = data["phone"] as? String ?? ""
            if let timestamp = data["birthdate"] as? Timestamp {
                self.birthdate = timestamp.dateValue()
            }
        }
    }

    func saveProfile() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid
        let email = user.email ?? ""

        isSaving = true
        errorMessage = nil
        
        Firestore.firestore().collection("users").document(uid).updateData([
            "name": name,
            "phone": phone.replacingOccurrences(of: "-", with: ""),
            "birthdate": birthdate,
            "email": email
        ]) { error in
            isSaving = false
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                let viewStore = ViewStore(store, observe: { $0 })
                viewStore.send(.profileCheckResult(false))
                
                if let userProfile = viewStore.userProfile {
                    var updateUserProfile = UserProfile(
                        uid: userProfile.uid,
                        name: self.name,
                        email: userProfile.email,
                        birthdate: self.birthdate,
                        phone: self.phone,
                        profileImageURL: userProfile.profileImageURL,
                        createdAt: userProfile.createdAt,
                        allowNotifications: userProfile.allowNotifications,
                        isPremium: userProfile.isPremium,
                        isAdmin: userProfile.isAdmin
                    )
                    viewStore.send(.userProfileLoaded(updateUserProfile))
                }
                dismiss()
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
