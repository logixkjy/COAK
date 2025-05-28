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
    @State private var showPrivacyPolicy = false
    @State private var isPresentingFineEmailSheet = false
    @State private var isPresentingResetPasswordSheet = false
    @State private var toastMessage: String? = nil
    @FocusState private var focusedField: Field?
    
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
                    
                    Text(viewStore.isSignUpMode ? "join_title" : "login_title")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .padding(.top, 24)
                    
                    Group {
                        Text("login_id_hint")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("login_id_hint", text: viewStore.$email)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .email)
                                .foregroundColor(.white)
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
                        
                        Text("login_pw_hint")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 16)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("login_pw_hint", text: viewStore.$password)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .password)
                                .foregroundColor(.white)
                                .onChange(of: viewStore.password) { newValue in
                                    if newValue.count > 20 {
                                        viewStore.send(.setPassword(String(newValue.prefix(20))))
                                    }
                                }
                            
                            if viewStore.isSignUpMode {
                                HStack {
                                    Text("login_pw_helper")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 16)
                                    Spacer()
                                    Text("\(viewStore.password.count)/20")
                                        .font(.footnote)
                                        .foregroundColor(.white)
                                        .padding(.trailing, 16)
                                }
                            }
                        }
                        
                        if viewStore.isSignUpMode {
                            Text("join_pw_hint2")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                            
                            SecureField("join_pw_hint2", text: viewStore.$confirmPassword)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .confirmPassword)
                                .foregroundColor(.white)
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
                            
                            
                            Text("join_name_hint")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                            
                            TextField("join_name_hint", text: viewStore.$name)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .name)
                                .foregroundColor(.white)
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
                            
                            
                            Text("join_phone_hint")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 16)
                            
                            TextField("join_phone_hint", text: viewStore.$phone)
                                .keyboardType(.phonePad)
                                .textFieldStyleCustom()
                                .focused($focusedField, equals: .phone)
                                .foregroundColor(.white)
                                .onChange(of: viewStore.phone) { newValue in
                                    if newValue.count > 11 {
                                        viewStore.send(.setPhone(String(newValue.prefix(11))))
                                    }
                                }
                            
                            HStack {
                                Text("join_phone_helper")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.trailing, 16)
                                Spacer()
                                Text("\(viewStore.phone.count)/11")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                                    .padding(.trailing, 16)
                            }
                            
                            DatePicker("join_birthday_title", selection: viewStore.$birthdate, displayedComponents: .date)
                                .padding(.top, 16)
                            
                            HStack {
                                Button(action: {
                                    showPrivacyPolicy = true
                                }) {
                                    Label("join_policy", systemImage: "doc.text")
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: viewStore.binding(get: \.agreeToTerms, send: AuthFeature.Action.setAgreeToTerms))
                                    .labelsHidden()
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
                        Text(viewStore.isSignUpMode ? "join_button" : "login_button")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.top, 24)
                    
                    Button(viewStore.isSignUpMode ? "join_already" : "login_button_join") {
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
                            
                            Button("login_button_pw_search") {
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
                        url: URL(string: "https://logixkjy.github.io/coak-privacy-policy")!,
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
            .onDisappear {
                viewStore.send(.clear)
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("common_close") {
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
            .background(Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1)
            )
            .textInputAutocapitalization(.never)
    }
}
