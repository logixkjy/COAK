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
                VStack(spacing: 16) {
                    Text("공지 제목")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("푸시 제목", text: $title)
                        .textFieldStyleCustom()
                        .focused($focusedField, equals: .title)
                        .foregroundColor(.black)
                    
                    Text("푸시 내용")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("푸시 내용", text: $content)
                        .textFieldStyleCustom()
                        .focused($focusedField, equals: .content)
                        .foregroundColor(.black)
                    
                    Button("Send Push") {
                        viewStore.send(.sendPush(title, content))
                    }
                    
                    Text(viewStore.pushResult)
                        .padding()
                        .foregroundColor(.green)
                    
                    Spacer()
                }
                .navigationTitle("푸시 발송")
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("완료") {
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
