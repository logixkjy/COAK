//
//  AuthView.swift
//  PlayListApp
//
//  Created by JooYoung Kim on 4/6/25.
//

import SwiftUI
import ComposableArchitecture

struct AuthView: View {
    let store: StoreOf<AuthFeature>
    @FocusState private var focusedField: Field?
    @State private var showPrivacyPolicy = false

    enum Field: Hashable {
        case email, password, confirmPassword, name, phone, authcode
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 24) {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.top, 32)

                    Text(viewStore.isSignUpMode ? "회원가입" : "로그인")
                        .font(.title.bold())
                        .foregroundColor(.white)

                    Group {
                        TextField("이메일 주소", text: viewStore.binding(get: \.email, send: AuthFeature.Action.setEmail))
                            .textFieldStyleCustom()
                            .focused($focusedField, equals: .email)
                            .foregroundColor(.black)

                        SecureField("비밀번호", text: viewStore.binding(get: \.password, send: AuthFeature.Action.setPassword))
                            .textFieldStyleCustom()
                            .focused($focusedField, equals: .password)
                            .foregroundColor(.black)

                        if viewStore.isSignUpMode {
                            SecureField("비밀번호 확인", text: viewStore.binding(get: \.confirmPassword, send: AuthFeature.Action.setConfirmPassword))
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .confirmPassword)
                                .foregroundColor(.black)

                            TextField("이름", text: viewStore.binding(get: \.name, send: AuthFeature.Action.setName))
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .name)
                                .foregroundColor(.black)

                            DatePicker("생년월일", selection: viewStore.binding(get: \.birthdate, send: AuthFeature.Action.setBirthdate), displayedComponents: .date)

                            TextField("전화번호", text: viewStore.binding(get: \.phone, send: AuthFeature.Action.setPhone))
                                .keyboardType(.phonePad)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .phone)
                                .foregroundColor(.black)

                            HStack {
                                Button(action: {
                                    showPrivacyPolicy = true
                                }) {
                                    Label("개인정보 처리방침", systemImage: "doc.text")
                                }

                                Spacer()

                                Toggle("동의함", isOn: viewStore.binding(get: \.agreeToTerms, send: AuthFeature.Action.setAgreeToTerms))
                                    .disabled(true)
                            }
                            .font(.caption)
                            .foregroundColor(.black)

                        }
                    }
                    .padding(.bottom, 6)

                    if let error = viewStore.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Button(action: {
                        viewStore.send(viewStore.isSignUpMode ? .signUpTapped : .loginTapped)
                    }) {
                        Text(viewStore.isSignUpMode ? "회원가입 완료" : "로그인")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top)

                    Button(viewStore.isSignUpMode ? "이미 계정이 있어요" : "회원가입하기") {
                        viewStore.send(.toggleSignUpMode)
                    }
                    .font(.headline)
                    .foregroundColor(.white)

                    if viewStore.isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal, 24)
                .sheet(isPresented: $showPrivacyPolicy) {
                    SafariWebView(
                        url: URL(string: "https://logixkjy.github.io/privacy.html")!,
                        onAgree: {
                            viewStore.send(.setAgreeToTerms(true))
                        }
                    )
                }
            }
            .background(Color.blue01.ignoresSafeArea())
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
}

extension View {
    func textFieldStyleCustom() -> some View {
        self
            .padding(12)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1))
    }
}
