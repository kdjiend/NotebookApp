//
//  CategoryViewModel.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import Foundation
import CoreData

@MainActor
class CategoryViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext

    @Published var categories: [Category] = []

    init(context: NSManagedObjectContext) {
        self.viewContext = context
        fetchRootCategories()
    }

    func fetchRootCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "parent == nil")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        do {
            categories = try viewContext.fetch(request)
        } catch {
            print("Failed to fetch categories: \(error)")
        }
    }

    func addCategory(name: String, parent: Category? = nil) {
        let newCategory = Category(context: viewContext)
        newCategory.id = UUID()
        newCategory.name = name
        newCategory.parent = parent

        saveContext()
        fetchRootCategories()
    }

    func deleteCategory(_ category: Category) {
        viewContext.delete(category)
        saveContext()
        fetchRootCategories()
    }

    func updateCategory(_ category: Category, newName: String) {
        category.name = newName
        saveContext()
        fetchRootCategories()
    }

    private func saveContext() {
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
}
