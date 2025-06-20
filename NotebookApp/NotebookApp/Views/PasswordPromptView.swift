//
//  PasswordPromptView.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import SwiftUI
import CoreData

struct PasswordPromptView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var noteVM: NoteViewModel
    @State private var password = ""
    // errorMessage 现在完全由 noteVM 提供
    // @State private var errorMessage: String? // <-- 移除此行
    @State private var showingEditor = false

    var onDismiss: () -> Void // 新增：关闭时的回调

    init(note: Note, context: NSManagedObjectContext, onDismiss: @escaping () -> Void = {}) {
        _noteVM = StateObject(wrappedValue: NoteViewModel(note: note, context: context))
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 20) {
            SecureField("Enter password", text: $password)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if let error = noteVM.errorMessage { // 直接显示 NoteViewModel 的错误信息
                Text(error)
                    .foregroundColor(.red)
            }

            HStack {
                // MARK: 解决问题 2 - 添加 Cancel 按钮
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                    onDismiss() // 调用回调
                }
                .buttonStyle(.bordered)
                
                Spacer()

                Button("Unlock") {
                    noteVM.unlock(password: password)
                    if noteVM.errorMessage == nil { // 只有在没有错误时才显示编辑器
                        showingEditor = true
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
        .sheet(isPresented: $showingEditor, onDismiss: {
            // 编辑器关闭后，确保密码提示视图也关闭
            presentationMode.wrappedValue.dismiss()
            onDismiss() // 调用回调
        }) {
            // 关键修正：将输入的密码传递给 NoteEditorView，以便它知道当前笔记的密码
            NoteEditorView(note: noteVM.note, password: password, context: viewContext)
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}
