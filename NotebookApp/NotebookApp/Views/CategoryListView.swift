//
//  CategoryListView.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import SwiftUI
import CoreData


struct CategoryListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @StateObject private var categoryVM: CategoryViewModel

    init(context: NSManagedObjectContext) {
        _categoryVM = StateObject(wrappedValue: CategoryViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(categoryVM.categories, id: \.self) { category in
                    NavigationLink(destination: NoteListView(category: category, context: viewContext)) {
                        Text(category.name ?? "(Unnamed Category)")
                    }
                    // MARK: macOS 解决方案 - 添加上下文菜单进行删除
                    .contextMenu {
                        Button(role: .destructive) {
                            // 调用 ViewModel 的删除方法
                            categoryVM.deleteCategory(category)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Categories")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        categoryVM.addCategory(name: "New Category")
                    }) {
                        Label("Add Category", systemImage: "folder.badge.plus")
                    }
                }
            }
            .onAppear {
                categoryVM.fetchRootCategories()
            }
        }
    }
}
