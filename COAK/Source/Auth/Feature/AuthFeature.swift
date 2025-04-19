//
//  AuthFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import FirebaseAuth
import FirebaseFirestore    

enum AuthError: Error, Equatable {
    case firebase(String)
    case unknown
}

struct UserProfile: Codable, Equatable {
    let uid: String
    let name: String?
    let email: String?
    let birthdate: Date?
    let phone: String?
    let profileImageURL: String?
    let createdAt: Date?
    let allowNotifications: Bool
    let isPremium: Bool?
}

struct AuthFeature: Reducer {
    struct State: Equatable {
        var email: String = ""
        var password: String = ""
        var confirmPassword: String = ""
        var name: String = ""
        var birthdate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
        var phone: String = ""
        var agreeToTerms = false
        
        var errorMessage: String? = nil
        var isLoading: Bool = false
        var showPrivacyPolicy: Bool = false
        var isSignUpMode: Bool = false
    }

    enum Action: Equatable {
        case setEmail(String)
        case setPassword(String)
        case setConfirmPassword(String)
        case setName(String)
        case setBirthdate(Date)
        case setPhone(String)
        case setInviteCode(String)
        case setAgreeToTerms(Bool)
        
        case toggleSignUpMode
        case loginTapped
        case signUpTapped
        case loginResponse(Result<Bool, AuthError>)
        case signUpResponse(Result<Bool, AuthError>)
        case loginSucceeded
        
        case setLoading(Bool)
        case setError(String?)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .setEmail(email):
                state.email = email
                return .none
                
            case let .setPassword(pw):
                state.password = pw
                return .none
                
            case let .setConfirmPassword(pw):
                state.confirmPassword = pw
                return .none
                
            case let .setName(name):
                state.name = name
                return .none
                
            case let .setBirthdate(date):
                state.birthdate = date
                return .none
                
            case let .setPhone(phone):
                state.phone = phone
                return .none
                
            case let .setAgreeToTerms(value):
                state.agreeToTerms = value
                return .none
                
            case .toggleSignUpMode:
                state.isSignUpMode.toggle()
                state.errorMessage = nil
                return .none

            case .loginTapped:
                state.isLoading = true
                state.errorMessage = nil
                return .run { [email = state.email, password = state.password] send in
                    do {
                        let result = try await Auth.auth().signIn(withEmail: email, password: password)
                        let uid = result.user.uid
                        let userEmail = result.user.email ?? ""

                        // ✅ Firestore에 email 병합 저장
                        let update: [String: Any] = ["email": userEmail]
                        try await Firestore.firestore().collection("users").document(uid).setData(update, merge: true)

                        await send(.loginSucceeded)
                    } catch {
                        await send(.loginResponse(.failure(.firebase(error.localizedDescription))))
                    }
                }

            case let .loginResponse(.failure(err)):
                state.isLoading = false
                state.errorMessage = "로그인 실패: \(err.localizedDescription)"
                return .none

            case .signUpTapped:
                guard state.password == state.confirmPassword else {
                    state.errorMessage = "비밀번호가 일치하지 않습니다."
                    return .none
                }
                guard state.agreeToTerms else {
                    state.errorMessage = "개인정보 처리방침에 동의해주세요."
                    return .none
                }
                
                state.isLoading = true
                state.errorMessage = nil
                return .run { [
                    email = state.email,
                    password = state.password,
                    name = state.name,
                    birthdate = state.birthdate,
                    phone = state.phone
                ] send in
                    do {
                        let result = try await Auth.auth().createUser(withEmail: email, password: password)
                        let uid = result.user.uid

                        let profile = UserProfile(
                            uid: uid,
                            name: name,
                            email: email,
                            birthdate: birthdate,
                            phone: phone,
                            profileImageURL: "",
                            createdAt: Date(),
                            allowNotifications: true,
                            isPremium: false
                        )

                        let db = Firestore.firestore()
                        try db.collection("users").document(uid).setData(from: profile)

                        await send(.loginSucceeded)
                    } catch {
                        await send(.signUpResponse(.failure(.firebase(error.localizedDescription))))
                    }
                }

            case let .signUpResponse(.failure(err)):
                state.isLoading = false
                state.errorMessage = "회원가입 실패: \(err.localizedDescription)"
                return .none

            case .loginSucceeded:
                state.isLoading = false
                return .none

            default:
                return .none
            }
        }
    }
}
