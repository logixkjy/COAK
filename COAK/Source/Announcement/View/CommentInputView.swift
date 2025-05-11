//
//  CommentInputView.swift
//  COAK
//
//  Created by JooYoung Kim on 5/8/25.
//

import SwiftUI
import Combine
import ComposableArchitecture

struct CommentInputView: View {
    @Binding var text: String
    @State var tempText: String = ""
    @Binding var isReply: Bool
    @Binding var isEdit: Bool
    @Binding var isFocusedExternal: Bool
    
    @FocusState private var isFocused: Bool
    @State private var showDiscardAlert = false

    var onSubmit: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background when keyboard is visible
            if isFocused {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        if (isReply || isEdit) && (isEdit ? tempText != text : !text.isEmpty) {
                            showDiscardAlert = true
                        } else {
                            text = ""
                            dismissKeyboard()
                        }
                    }
            }

            VStack {
                Spacer()

                HStack {
                    TextField("\(isReply ? "답글" : "댓글") \(isEdit ? "수정" : "추가")...", text: $text)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(10)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(20)
                        .focused($isFocused)

                    Button(action: submitComment) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor((isEdit ? tempText == text : text.isEmpty) ? .gray : .blue)
                    }
                    .disabled((isEdit ? tempText == text : text.isEmpty))
                }
                .padding(.horizontal)
                .frame(maxWidth: .infinity)
                .frame(height: isFocused ? 50 : 60) // 기본 상태와 입력 상태 크기 구분
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 3)
                .padding(.bottom, isFocused ? 0 : 16)
                .animation(.easeInOut, value: isFocused)
            }
        }
        .alert("수정사항을 삭제할까요?", isPresented: $showDiscardAlert) {
            Button("계속 작성", role: .cancel) {}
            Button("삭제", role: .destructive) {
                text = ""
                dismissKeyboard()
            }
        }
        .onChange(of: isFocusedExternal) { newValue in
            isFocused = newValue
        }
        .onChange(of: isEdit) { newValue in
            if newValue {
                tempText = text
            } else {
                tempText = ""
            }
        }
        .onAppear {
            isFocused = isFocusedExternal
        }
    }

    private func submitComment() {
        guard !text.isEmpty else { return }
        onSubmit(text)
        text = ""
        dismissKeyboard()
    }

    private func dismissKeyboard() {
        isFocused = false
        isFocusedExternal = false
        isReply = false
        isEdit = false
        onCancel()
    }
}
