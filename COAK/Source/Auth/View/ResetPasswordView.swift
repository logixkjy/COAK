//
//  ResetPasswordView.swift
//  COAK
//
//  Created by JooYoung Kim on 4/26/25.
//

import SwiftUI
import ComposableArchitecture

struct ResetPasswordView: View {
    let store: StoreOf<AuthFeature>
    @FocusState private var focusedField: Field?
    
    @Environment(\.dismiss) private var dismiss
    
    enum Field: Hashable {
        case email
    }

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding(.top, 32)
                
                Text("비밀번호 재설정")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                Text("이메일")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                
                TextField("이메일을 입력하세요", text: viewStore.$findEmail)
                    .textFieldStyleCustom()
                    .focused($focusedField, equals: .email)
                    .foregroundColor(.black)

                Button(action: {
                    viewStore.send(.resetPasswordButtonTapped)
                }) {
                    if viewStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("재설정 메일 보내기")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .disabled(viewStore.findEmail.isEmpty || viewStore.isLoading)
                .padding(.top, 24)

                if let successMessage = viewStore.successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .padding()

                    Button("닫기") {
                        dismiss()
                    }
                    .padding()
                }

                if let errorMessage = viewStore.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .padding(.horizontal, 24)
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
