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
    @State private var isPresentingFineEmailSheet = false
    @State private var isPresentingResetPasswordSheet = false

    enum Field: Hashable {
        case email, password, confirmPassword, name, phone, authcode
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 0) {
                    Image(.logo)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200)
                        .padding(.top, 32)

                    Text(viewStore.isSignUpMode ? "회원가입" : "로그인")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding(.top, 24)

                    Group {
                        Text("이메일 아이디")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        TextField("이메일 주소", text: viewStore.$email)
                            .textFieldStyleCustom()
                            .focused($focusedField, equals: .email)
                            .foregroundColor(.black)
                        
                        Text("비밀번호")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        SecureField("비밀번호", text: viewStore.$password)
                            .textFieldStyleCustom()
                            .focused($focusedField, equals: .password)
                            .foregroundColor(.black)

                        if viewStore.isSignUpMode {
                            Text("비밀번호 확인")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                            
                            SecureField("비밀번호 확인", text: viewStore.$confirmPassword)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .confirmPassword)
                                .foregroundColor(.black)
                            
                            
                            Text("이름")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                                
                            TextField("이름", text: viewStore.$name)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .name)
                                .foregroundColor(.black)
                            
                            DatePicker("생년월일", selection: viewStore.$birthdate, displayedComponents: .date)
                                .padding(.top, 16)
                            
                            
                            Text("전화번호")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                                
                            TextField("전화번호", text: viewStore.$phone)
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

                                Toggle("동의여부", isOn: viewStore.binding(get: \.agreeToTerms, send: AuthFeature.Action.setAgreeToTerms))
                                    .disabled(true)
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.top, 16)

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
                    .padding(.top, 24)

                    Button(viewStore.isSignUpMode ? "이미 계정이 있어요" : "회원가입하기") {
                        viewStore.send(.toggleSignUpMode)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    
                    if !viewStore.isSignUpMode {
                        HStack() {
                            Button("아이디 찾기") {
                                isPresentingFineEmailSheet.toggle()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            
                            Text("|")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Button("비밀번호 찾기") {
                                isPresentingResetPasswordSheet.toggle()
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        .padding(.top, 24)
                    }

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
                .sheet(isPresented: $isPresentingFineEmailSheet) {
                    FindEmailView(
                        store: store
                    )
                }
                .sheet(isPresented: $isPresentingResetPasswordSheet) {
                    ResetPasswordView(
                        store: store
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
