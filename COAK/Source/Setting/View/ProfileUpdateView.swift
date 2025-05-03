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

    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case name
        case phone
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("이름")) {
                    TextField("이름을 입력하세요", text: $name)
                        .focused($focusedField, equals: .name)
                }

                Section(header: Text("전화번호")) {
                    TextField("010-1234-5678", text: $phone)
                        .keyboardType(.numberPad)
                        .onChange(of: phone) { newValue in
                            self.phone = formatPhoneNumber(newValue)
                        }
                        .focused($focusedField, equals: .phone)
                }

                Section(header: Text("생년월일")) {
                    DatePicker("", selection: $birthdate, displayedComponents: .date)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("저장")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("내 정보 입력")
            .onAppear {
                loadUserProfile()
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

        let data: [String: Any] = [
            "name": name,
            "phone": phone,
            "birthdate": birthdate,
            "email": email
        ]

        Firestore.firestore().collection("users").document(uid).setData(data, merge: true) { error in
            isSaving = false
            if let error = error {
                self.errorMessage = error.localizedDescription
            } else {
                let viewStore = ViewStore(store, observe: { $0 })
                viewStore.send(.profileCheckResult(false))
                dismiss()
            }
        }
    }
}
