//
//  NoteEditorView.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import SwiftUI
import CoreData

struct NoteEditorView: View {
    @Environment(\.presentationMode) var presentationMode

    @StateObject private var noteVM: NoteViewModel

    @State private var contentText: String = ""
    @State private var currentPassword: String // 允许用户在编辑器中设置/更改密码
    @State private var showPasswordEntryForNewNote: Bool = false // 控制新笔记是否显示密码输入框
    
    var onDismiss: () -> Void // 新增：关闭时的回调

    init(note: Note, password: String, context: NSManagedObjectContext, onDismiss: @escaping () -> Void = {}) {
        _noteVM = StateObject(wrappedValue: NoteViewModel(note: note, context: context))
        _currentPassword = State(initialValue: password) // 初始化 currentPassword
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            TextField("Untitled", text: Binding( // 使用 TextField 作为标题输入
                get: { noteVM.note.title ?? "" },
                set: { newTitle in
                    noteVM.note.title = newTitle.isEmpty ? "Untitled" : newTitle
                }
            ))
            .font(.title2)
            .textFieldStyle(.plain) // macOS 风格的文本框
            .padding(.horizontal)

            TextEditor(text: $contentText)
                .padding()
                .frame(minHeight: 300)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            if let error = noteVM.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            // 只有在新笔记且尚未设置密码时显示密码输入框
            if noteVM.note.encryptedData!.isEmpty && showPasswordEntryForNewNote {
                SecureField("Set Password for this Note", text: $currentPassword)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            HStack {
                // MARK: 解决问题 3 - 添加 Cancel 按钮
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                    onDismiss() // 调用回调
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Save") {
                    // MARK: 优化点1 - 内容为空时不保存
                    let trimmedContent = contentText.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedContent.isEmpty {
                        noteVM.errorMessage = "笔记内容不能为空。"
                        return // 阻止保存
                    }

                    // 如果是新建笔记且密码为空，提示用户输入密码
                    // 如果笔记是空的，并且用户没有设置密码，则提示
                    if noteVM.note.encryptedData!.isEmpty && currentPassword.isEmpty {
                        noteVM.errorMessage = "请为新笔记设置一个密码。"
                        showPasswordEntryForNewNote = true // 强制显示密码输入框
                        return
                    }

                    noteVM.save(content: contentText, password: currentPassword)
                    if noteVM.errorMessage == nil {
                        presentationMode.wrappedValue.dismiss()
                        onDismiss() // 调用回调
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            if noteVM.note.encryptedData!.isEmpty {
                // 🟢 新建笔记，跳过解密，内容为空
                contentText = ""
                currentPassword = "" // 确保新笔记的密码为空，待用户输入
                showPasswordEntryForNewNote = true // 默认显示密码输入框
            } else {
                // 🔒 尝试解密旧笔记，使用传入的密码
                noteVM.unlock(password: currentPassword)
                // 如果解锁成功，则显示内容；否则内容将为空，且会显示错误信息
                contentText = noteVM.decryptedContent
                showPasswordEntryForNewNote = false // 旧笔记不需要显示密码设置
            }
        }
    }
}
