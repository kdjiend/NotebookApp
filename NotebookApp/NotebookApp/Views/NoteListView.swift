//
//  NoteListView.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import SwiftUI
import CoreData

struct NoteListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var category: Category

    @FetchRequest private var notes: FetchedResults<Note>

    @State private var showingPasswordPrompt = false // 用于旧笔记的密码提示
    @State private var showingNewNoteEditor = false // 新增：用于新笔记的编辑器
    @State private var selectedNote: Note?

    init(category: Category, context: NSManagedObjectContext) {
        self.category = category
        // 确保 FetchRequest 使用正确的 predicate 来筛选指定分类的笔记
        _notes = FetchRequest(
            entity: Note.entity(),
            sortDescriptors: [NSSortDescriptor(key: "createdAt", ascending: false)],
            predicate: NSPredicate(format: "category == %@", category),
            animation: .default
        )
    }

    var body: some View {
        List {
            ForEach(notes, id: \.self) { note in
                Button {
                    selectedNote = note
                    // 如果笔记是新创建但尚未加密的，直接打开编辑器；否则弹出密码提示
                    // 注意：这里的 note.encryptedData 可能为空，但我们依赖 addNote 时的 showingNewNoteEditor
                    // 最好还是通过一个状态变量来区分是打开现有笔记还是新创建的笔记
                    if note.encryptedData?.isEmpty ?? true { // 如果笔记数据为空，可能是未保存的新笔记
                         // 这种情况下，其实不应该通过 Button 触发，Button 应该只用于已存在的笔记
                         // 如果用户点击了一个空笔记（不该出现），这里避免弹出密码框
                         // 理论上，已保存的空笔记不应存在，除非是刚创建的。
                         // 这里保留 showingPasswordPrompt = true 是为了已加密笔记
                        showingPasswordPrompt = true
                    } else {
                        showingPasswordPrompt = true // 旧笔记需要密码解锁
                    }
                } label: {
                    Text(note.title ?? "(Untitled)")
                }
                // MARK: 解决问题 1 - 增加上下文菜单删除笔记
                .contextMenu {
                    Button(role: .destructive) {
                        deleteNotes(note) // 调用新的删除单个笔记的方法
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            // .onDelete(perform: deleteNotes) // <-- 移除此行，我们使用上下文菜单代替
        }
        .navigationTitle(category.name ?? "Notes")
        .toolbar {
            ToolbarItem {
                Button(action: addNote) {
                    Label("Add Note", systemImage: "square.and.pencil")
                }
            }
        }
        // 对于旧笔记，弹出密码提示
        .sheet(isPresented: $showingPasswordPrompt) {
            if let note = selectedNote {
                PasswordPromptView(note: note, context: viewContext, onDismiss: { // 新增 onDismiss 回调
                    // 当 PasswordPromptView 关闭时，确保 errorMessage 被清除
                    // 并且如果解锁失败，selectedNote 应该被重置，避免再次尝试打开
                    self.selectedNote = nil
                })
                .frame(minWidth: 600, minHeight: 400)
            }
        }
        // MARK: 解决问题 4 - 对于新笔记，直接弹出编辑器
        .sheet(isPresented: $showingNewNoteEditor, onDismiss: {
            // 当新笔记编辑器关闭时，如果该笔记内容为空（意味着用户取消或未保存），则删除它
            if let note = selectedNote, note.encryptedData?.isEmpty ?? true {
                // 如果标题还是 "New Note" 且没有加密数据，认为是未保存的空笔记
                if note.title == "New Note" && (note.encryptedData?.isEmpty ?? true) {
                    viewContext.delete(note)
                    do {
                        try viewContext.save()
                    } catch {
                        print("Failed to delete empty new note: \(error.localizedDescription)")
                    }
                }
            }
            self.selectedNote = nil // 确保 selectedNote 被清除
        }) {
            if let note = selectedNote { // 这里的 selectedNote 会是新创建的笔记
                NoteEditorView(note: note, password: "", context: viewContext, onDismiss: {
                    // NoteEditorView 关闭时，这个回调可以用来刷新列表或处理后续逻辑
                    // 实际的空笔记删除逻辑在 onDismiss of showingNewNoteEditor
                })
                    .frame(minWidth: 600, minHeight: 400)
            }
        }
    }

    private func addNote() {
        withAnimation {
            let newNote = Note(context: viewContext)
            newNote.id = UUID()
            newNote.title = "New Note" // 初始标题
            newNote.createdAt = Date()
            newNote.updatedAt = Date()
            // 新建笔记时，这些字段应为空，直到保存时才加密填充
            newNote.encryptedData = Data()
            newNote.salt = Data()
            newNote.nonce = Data()
        
            newNote.category = category

            do {
                try viewContext.save()
                selectedNote = newNote
                showingNewNoteEditor = true // 关键修正：直接显示新笔记编辑器
            } catch {
                print("保存笔记失败: \(error.localizedDescription)")
            }
        }
    }

    // MARK: 解决问题 1 - 删除单个笔记的方法 (用于上下文菜单)
    private func deleteNotes(_ note: Note) {
        withAnimation {
            viewContext.delete(note)
            do {
                try viewContext.save()
            } catch {
                print("Failed to delete note: \(error)")
            }
        }
    }

    // 移除原有的 deleteNotes(offsets: IndexSet) 方法，因为不再使用 .onDelete 修饰符
    // private func deleteNotes(offsets: IndexSet) { ... }
}
