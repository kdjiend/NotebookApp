//
//  Persistence.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for i in 0..<10 {
            let newNote = Note(context: viewContext)
            newNote.id = UUID()
            newNote.title = "Sample Note \(i)"
            newNote.createdAt = Date()
            newNote.updatedAt = Date()
            newNote.encryptedData = Data() // placeholder
            newNote.salt = Data()
            newNote.nonce = Data()
            

            // 添加一些分类数据用于预览
            if i % 3 == 0 {
                let newCategory = Category(context: viewContext)
                newCategory.id = UUID()
                newCategory.name = "Sample Category \((i/3)+1)"
                newNote.category = newCategory
            } else if i % 3 == 1 {
                // 如果需要，可以为现有分类添加笔记
                if let existingCategory = try? viewContext.fetch(Category.fetchRequest()).first(where: { $0.name == "Sample Category 1" }) {
                    newNote.category = existingCategory
                }
            }
        }
        do {
            try viewContext.save()
        } catch {
            // 在预览模式下，如果保存失败，打印错误而不是致命错误
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NotebookModel")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // 实际应用中，这里应该有更健壮的错误处理，例如记录日志或通知用户
                // 但对于应用启动时的核心数据加载失败，fatalError 也是一种常见的处理方式
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
