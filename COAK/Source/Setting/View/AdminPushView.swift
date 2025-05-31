//
//  AdminPushView.swift
//  COAK
//
//  Created by JooYoung Kim on 5/14/25.
//

import SwiftUI
import ComposableArchitecture

struct AdminPushView: View {
    let store: StoreOf<AdminPushFeature>
    @State private var title: String = ""
    @State private var content: String = ""
    
    @FocusState private var focusedField: Field?
    enum Field: Hashable {
        case title
        case content
    }
    
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                ZStack {
                    Color.black01.ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Text("push_send_notice_title")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.leading, .trailing], 8)
                        
                        TextField("push_send_notice_title", text: $title)
                            .textFieldStyleCustom()
                            .focused($focusedField, equals: .title)
                            .foregroundColor(.white)
                            .padding([.leading, .trailing], 8)
                        
                        Text("push_send_notice_message")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding([.leading, .trailing], 8)
                        
                        TextField("push_send_notice_message", text: $content)
                            .textFieldStyleCustom()
                            .focused($focusedField, equals: .content)
                            .foregroundColor(.white)
                            .padding([.leading, .trailing], 8)
                        
                        Button("push_send_btn") {
                            viewStore.send(.sendPush(title, content))
                        }
                        
                        Text(viewStore.pushResult)
                            .padding()
                            .foregroundColor(.green)
                        
                        Spacer()
                    }
                }
                .navigationTitle("push_send_title")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("common_close") {
                            focusedField = nil
                        }
                    }
                }
                .onChange(of: viewStore.isSuccess) { newValue in
                    if newValue {
                        title = ""
                        content = ""
                        focusedField = nil
                    } else {
                        
                    }
                }
            }
        }
    }
}
