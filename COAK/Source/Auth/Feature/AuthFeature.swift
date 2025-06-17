//
//  AuthFeature.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/5/25.
//

import ComposableArchitecture
import FirebaseAuth
import FirebaseFirestore
import SwiftUICore

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
    let isAdmin: Bool?
}

struct AuthFeature: Reducer {
    struct State: Equatable {
        @BindingState var email: String = ""
        @BindingState var password: String = ""
        @BindingState var confirmPassword: String = ""
        @BindingState var name: String = ""
        @BindingState var birthdate: Date = Calendar.current.date(byAdding: .year, value: -20, to: Date()) ?? Date()
        @BindingState var phone: String = ""
        var agreeToTerms = false
        
        var successMessage: String?
        var errorMessage: String? = nil
        var isLoading: Bool = false
        var showPrivacyPolicy: Bool = false
        var isSignUpMode: Bool = false
        
        @BindingState var findName: String = ""
        @BindingState var findPhone: String = ""
        var foundEmail: String? = nil
        
        @BindingState var findEmail: String = ""
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        
        case setEmail(String)
        case setPassword(String)
        case setConfirmPassword(String)
        case setName(String)
        case setPhone(String)
        case setAgreeToTerms(Bool)
        
        case toggleSignUpMode
        case loginTapped
        case signUpTapped
        case loginResponse(Result<Bool, CustomError>)
        case signUpResponse(Result<Bool, CustomError>)
        case loginSucceeded
        
        case setLoading(Bool)
        case setError(String?)
        
        case findEmailButtonTapped
        case findEmailResponse(Result<String, CustomError>)

        case resetPasswordButtonTapped
        case resetPasswordResponseSuccess
        case resetPasswordResponseFailure(CustomError)
        
        case clear
    }

    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding(_):
                return .none
                
            case let .setEmail(value):
                state.email = value
                return .none
                
            case let .setPassword(value):
                state.password = value
                return .none
                
            case let .setConfirmPassword(value):
                state.confirmPassword = value
                return .none
                
            case let .setName(value):
                state.name = value
                return .none
                
            case let .setPhone(value):
                state.phone = value
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
                        await send(.loginResponse(.failure(.firebaseError(error.localizedDescription))))
                    }
                }

            case let .loginResponse(.failure(err)):
                state.isLoading = false
                state.errorMessage = NSLocalizedString("login_fail", comment: "") + ": \(err.localizedDescription)"
                return .none

            case .signUpTapped:
                state.errorMessage = ""
                
                guard !state.email.isEmpty else {
                    state.errorMessage = NSLocalizedString("join_id_error", comment: "")
                    return .none
                }
                guard isValidEmail(state.email) else {
                    state.errorMessage = NSLocalizedString("join_email_error", comment: "")
                    return .none
                }
                guard !state.password.isEmpty else {
                    state.errorMessage = NSLocalizedString("login_pw_error", comment: "")
                    return .none
                }
                guard state.password == state.confirmPassword else {
                    state.errorMessage = NSLocalizedString("login_pw_error2", comment: "")
                    return .none
                }
                guard state.agreeToTerms else {
                    state.errorMessage = NSLocalizedString("login_policy_error", comment: "")
                    return .none
                }
                guard !state.name.isEmpty else {
                    state.errorMessage = NSLocalizedString("join_name_error", comment: "")
                    return .none
                }
//                guard state.phone.count >= 8, state.phone.count <= 11 else {
//                    state.errorMessage = NSLocalizedString("join_phone_error", comment: "")
//                    return .none
//                }
                
                state.isLoading = true
                state.errorMessage = nil
                return .run { [
                    email = state.email,
                    password = state.password,
                    name = state.name
//                    birthdate = state.birthdate,
//                    phone = state.phone
                ] send in
                    do {
                        let result = try await Auth.auth().createUser(withEmail: email, password: password)
                        let uid = result.user.uid

                        let profile = UserProfile(
                            uid: uid,
                            name: name,
                            email: email,
                            birthdate: nil,
                            phone: "",
                            profileImageURL: "",
                            createdAt: Date(),
                            allowNotifications: true,
                            isPremium: false,
                            isAdmin: false
                        )

                        let db = Firestore.firestore()
                        try db.collection("users").document(uid).setData(from: profile)

                        await send(.loginSucceeded)
                    } catch {
                        await send(.signUpResponse(.failure(.firebaseError(error.localizedDescription))))
                    }
                }

            case let .signUpResponse(.failure(err)):
                state.isLoading = false
                state.errorMessage = NSLocalizedString("join_fail",comment: "") + ": \(err.localizedDescription)"
                return .none

            case .loginSucceeded:
                state.isLoading = false
                return .none
                
            case .findEmailButtonTapped:
                state.isLoading = true
                state.errorMessage = nil
                state.foundEmail = nil
                return .run { [name = state.findName, phone = state.findPhone] send in
                    let db = Firestore.firestore()
                    do {
                        let snapshot = try await db.collection("users")
                            .whereField("name", isEqualTo: name)
                            .whereField("phone", isEqualTo: phone)
                            .getDocuments()

                        guard let document = snapshot.documents.first,
                              let email = document.data()["email"] as? String else {
                            await send(.findEmailResponse(.failure(.notFound)))
                            return
                        }

                        await send(.findEmailResponse(.success(email)))
                    } catch {
                        await send(.findEmailResponse(.failure(.firebaseError(error.localizedDescription))))
                    }
                }

            case let .findEmailResponse(result):
                state.isLoading = false
                switch result {
                case .success(let email):
                    state.foundEmail = email
                case .failure(let error):
                    state.errorMessage = error.localizedDescription
                }
                return .none
                
                
            case .resetPasswordButtonTapped:
                state.isLoading = true
                state.errorMessage = nil
                state.successMessage = nil
                return .run { [email = state.findEmail] send in
                    do {
                        try await Auth.auth().sendPasswordReset(withEmail: email)
                        await send(.resetPasswordResponseSuccess)
                    } catch {
                        await send(.resetPasswordResponseFailure(.firebaseError(error.localizedDescription)))
                    }
                }

            case .resetPasswordResponseSuccess:
                state.isLoading = false
                state.successMessage = NSLocalizedString("pw_search_send_message", comment: "")
                return .none
                
            case let .resetPasswordResponseFailure(result):
                state.errorMessage = result.localizedDescription
                return .none

            case .clear:
                state.isSignUpMode = false
                state.email = ""
                state.password = ""
                state.confirmPassword = ""
                state.name = ""
                state.phone = ""
                state.agreeToTerms = false
                return .none
                
            default:
                return .none
            }
        }
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }
}
