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
                
                Text("pw_search_title")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 24)
                
                Text("pw_search_email_title")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 16)
                    .padding(.bottom, 6)
                
                TextField("pw_search_email_title", text: viewStore.$findEmail)
                    .textFieldStyleCustom()
                    .focused($focusedField, equals: .email)
                    .foregroundColor(.white)

                Button(action: {
                    viewStore.send(.resetPasswordButtonTapped)
                }) {
                    if viewStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("pw_search_button")
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

                    Button("common_close") {
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
                    Button("common_close") {
                        focusedField = nil
                    }
                }
            }
        }
    }
}
