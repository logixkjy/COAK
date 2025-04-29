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
    @State private var toastMessage: String? = nil
    
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
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("이메일 주소", text: viewStore.$email)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .email)
                                .foregroundColor(.black)
                                .onChange(of: viewStore.email) { newValue in
                                    if newValue.count > 50 {
                                        viewStore.send(.setEmail(String(newValue.prefix(50))))
                                    }
                                }
                            if viewStore.isSignUpMode {
                                HStack {
                                    Spacer()
                                    Text("\(viewStore.email.count)/50")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        
                        Text("비밀번호")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("비밀번호", text: viewStore.$password)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .password)
                                .foregroundColor(.black)
                                .onChange(of: viewStore.password) { newValue in
                                    if newValue.count > 20 {
                                        viewStore.send(.setPassword(String(newValue.prefix(20))))
                                    }
                                }
                            
                            if viewStore.isSignUpMode {
                                HStack {
                                    Spacer()
                                    Text("\(viewStore.password.count)/20")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        
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
                                .onChange(of: viewStore.confirmPassword) { newValue in
                                    if newValue.count > 20 {
                                        viewStore.send(.setConfirmPassword(String(newValue.prefix(20))))
                                    }
                                }
                            
                            HStack {
                                Spacer()
                                Text("\(viewStore.confirmPassword.count)/20")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.trailing, 16)
                            }
                            
                            
                            Text("이름")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                            
                            TextField("이름", text: viewStore.$name)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .name)
                                .foregroundColor(.black)
                                .onChange(of: viewStore.name) { newValue in
                                    if newValue.count > 20 {
                                        viewStore.send(.setName(String(newValue.prefix(20))))
                                    }
                                }
                            
                            HStack {
                                Spacer()
                                Text("\(viewStore.name.count)/20")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.trailing, 16)
                            }
                            
                            DatePicker("생년월일", selection: viewStore.$birthdate, displayedComponents: .date)
                                .padding(.top, 16)
                            
                            
                            Text("전화번호")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                            
                            TextField("휴대전화번호", text: viewStore.$phone)
                                .keyboardType(.phonePad)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .phone)
                                .foregroundColor(.black)
                                .onChange(of: viewStore.phone) { newValue in
                                    if newValue.count > 11 {
                                        viewStore.send(.setPhone(String(newValue.prefix(11))))
                                    }
                                }
                            
                            HStack {
                                Spacer()
                                Text("\(viewStore.phone.count)/11")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.trailing, 16)
                            }
                            
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
                        viewStore.send(.setEmail(""))
                        viewStore.send(.setPassword(""))
                        viewStore.send(.setConfirmPassword(""))
                        viewStore.send(.setName(""))
                        viewStore.send(.setPhone(""))
                        viewStore.send(.toggleSignUpMode)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 24)
                    
                    if !viewStore.isSignUpMode {
                        HStack() {
//                            Button("아이디 찾기") {
//                                isPresentingFineEmailSheet.toggle()
//                            }
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            
//                            Text("|")
//                                .font(.headline)
//                                .foregroundColor(.white)
                            
                            Button("비밀번호를 잃어 버리셨나요?") {
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
                .onChange(of: viewStore.errorMessage) { newValue in
                    if let newValue = newValue {
                        showToast(message: newValue)
                    }
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
            .overlay(
                Group {
                    if let message = toastMessage {
                        VStack {
                            Spacer()
                            Text(message)
                                .padding()
                                .background(Color.black.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.bottom, 40)
                        }
                        .animation(.easeInOut, value: toastMessage)
                        .transition(.move(edge: .bottom))
                    }
                }
            )
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            toastMessage = nil
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
