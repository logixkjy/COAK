//
//  UserListView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/14/25.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserInfo: Identifiable, Decodable {
    var id: String { uid }
    let uid: String
    let name: String
    let phone: String
    let email: String
    let birthdate: Date?
    let profileImageURL: String?
    var isPremium: Bool
}

struct UserListView: View {
    @State private var users: [UserInfo] = []
    @State private var isLoading = false
    @State private var searchText: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black01.ignoresSafeArea()
                VStack(spacing: 0) {
                    // 검색창
                    TextField("setting_find_name", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                    
                    List(filteredUsers.indices, id: \.self) { index in
                        let user = filteredUsers[index]
                        
                        HStack(alignment: .top, spacing: 12) {
                            // 프로필 이미지
                            if let urlString = user.profileImageURL,
                               let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                } placeholder: {
                                    ProgressView()
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                            }
                            
                            // 사용자 정보와 프리미엄 여부 체크박스
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(user.name.isEmpty ? "-" : user.name)
                                        .font(.headline)
                                    
                                    Text(user.birthdate?.formatted(date: .numeric, time: .omitted) ?? "-")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    // 프리미엄 체크박스
                                    Toggle(isOn: Binding(
                                        get: { user.isPremium },
                                        set: { newValue in
                                            updatePremiumStatus(for: user.uid, isPremium: newValue)
                                            users[index].isPremium = newValue
                                        }
                                    )) {
//                                        Image(systemName: user.isPremium ? "star.fill" : "star")
//                                            .foregroundColor(user.isPremium ? .yellow : .gray)
                                    }
                                    .toggleStyle(.switch)
                                }
                                
                                Text(user.phone.isEmpty ? "-" : user.phone)
                                    .font(.caption)
                                Text(user.email.isEmpty ? "-" : user.email)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("setting_user_list")
            .onAppear {
                loadUsers()
            }
        }
        .overlay {
            if isLoading {
                ProgressView("loading...")
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
    }

    // Firestore에서 전체 사용자 불러오기
    func loadUsers() {
        isLoading = true
        Firestore.firestore().collection("users").getDocuments { snapshot, error in
            isLoading = false
            guard let documents = snapshot?.documents else { return }

            self.users = documents.compactMap { doc in
                let data = doc.data()

                // 비어있을 가능성이 있는 필드들을 안전하게 파싱
                let name = data["name"] as? String ?? "이름 없음"
                let phone = data["phone"] as? String ?? "연락처 없음"
                let email = data["email"] as? String ?? "이메일 없음"
                let birthTS = data["birthdate"] as? Timestamp
                let birthdate = birthTS?.dateValue()
                let profileImageURL = data["profileImageURL"] as? String
                let isPremium = data["isPremium"] as? Bool ?? false

                let uid = doc.documentID

                return UserInfo(
                    uid: uid,
                    name: name,
                    phone: phone,
                    email: email,
                    birthdate: birthdate,
                    profileImageURL: profileImageURL,
                    isPremium: isPremium
                )
            }
            
            self.users = self.users.sorted(by: { $0.name < $1.name })
        }
    }

    // Firestore에서 프리미엄 상태 업데이트
    func updatePremiumStatus(for uid: String, isPremium: Bool) {
        Firestore.firestore().collection("users").document(uid).updateData([
            "isPremium": isPremium
        ]) { error in
            if let error = error {
                print("Error updating premium status: \(error.localizedDescription)")
            } else {
                print("Premium status updated for user: \(uid)")
            }
        }
    }
    
    var filteredUsers: [UserInfo] {
        let keyword = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !keyword.isEmpty else { return users }

        return users.filter { user in
            let name = user.name.lowercased()
            return name.contains(keyword)
            || name.hangulInitials().contains(keyword)
        }
    }
}

extension String {
    func hangulInitials() -> String {
        let choSung = ["ㄱ", "ㄲ", "ㄴ", "ㄷ", "ㄸ", "ㄹ", "ㅁ", "ㅂ",
                       "ㅃ", "ㅅ", "ㅆ", "ㅇ", "ㅈ", "ㅉ", "ㅊ", "ㅋ",
                       "ㅌ", "ㅍ", "ㅎ"]

        return self.compactMap { char in
            guard let scalar = char.unicodeScalars.first else { return nil }
            let base = scalar.value
            guard (0xAC00...0xD7A3).contains(base) else { return nil }

            let index = (base - 0xAC00) / 28 / 21
            return choSung[Int(index)]
        }.joined()
    }
}
