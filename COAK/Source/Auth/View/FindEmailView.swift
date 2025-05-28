//
//  FindEmailView.swift
//  COAK
//
//  Created by JooYoung Kim on 4/26/25.
//

import SwiftUI
import FirebaseFirestore
import ComposableArchitecture

struct FindEmailView: View {
    let store: StoreOf<AuthFeature>
    
    @FocusState private var focusedField: Field?
    
    @Environment(\.dismiss) private var dismiss
    
    enum Field: Hashable {
        case name, phone
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                Image(.logo)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding(.top, 32)
                
                Text("아이디(이메일) 찾기")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                Text("이름")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                
                TextField("이름을 입력하세요", text: viewStore.$findName)
                    .textFieldStyleCustom()
                    .focused($focusedField, equals: .name)
                    .foregroundColor(.black)
                
                Text("전화번호")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                
                TextField("전화번호를 입력하세요", text: viewStore.$findPhone)
                    .keyboardType(.phonePad)
                    .textFieldStyleCustom()
                    .focused($focusedField, equals: .phone)
                    .foregroundColor(.black)
                
                Button(action: {
                    viewStore.send(.findEmailButtonTapped)
                }) {
                    if viewStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("이메일 찾기")
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                .disabled(viewStore.findName.isEmpty || viewStore.findPhone.isEmpty || viewStore.isLoading)
                .padding(.top, 24)
                
                if let foundEmail = viewStore.foundEmail {
                    Text("찾은 이메일: \(foundEmail)")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                    
                    Button("로그인하러 가기") {
                        viewStore.send(.setEmail(foundEmail))
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                }
                
                if let errorMessage = viewStore.errorMessage {
                    Text(errorMessage)
                        .font(.headline)
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
                    Button("common_close") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}
