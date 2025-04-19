//
//  UserListView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/14/25.
//

// UserListView.swift - 관리자 전용 유저 목록 뷰

import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserInfo: Identifiable, Decodable {
    var id: String { uid }
    let uid: String
    let name: String
    let phone: String
    let email: String
    let birthdate: Date
    let profileImageURL: String?
}

struct UserListView: View {
    @State private var users: [UserInfo] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List(users) { user in
                HStack(alignment: .top, spacing: 12) {
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

                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline) +
                        Text(" (\(calculateAge(from: user.birthdate))세)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(user.phone)
                            .font(.caption)
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 6)
            }
            .navigationTitle("전체 사용자")
            .onAppear {
                loadUsers()
            }
        }
    }

    func calculateAge(from birthdate: Date) -> Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year ?? 0
    }

    func loadUsers() {
        isLoading = true
        Firestore.firestore().collection("users").getDocuments { snapshot, error in
            isLoading = false
            guard let documents = snapshot?.documents else { return }

            self.users = documents.compactMap { doc in
                let data = doc.data()

                guard
                    let name = data["name"] as? String,
                    let phone = data["phone"] as? String,
                    let email = data["email"] as? String,
                    let birthTS = data["birthdate"] as? Timestamp
                else {
                    return nil
                }

                let uid = doc.documentID
                let birthdate = birthTS.dateValue()
                let profileImageURL = data["profileImageURL"] as? String

                return UserInfo(uid: uid, name: name, phone: phone, email: email, birthdate: birthdate, profileImageURL: profileImageURL)
            }
        }
    }
}
