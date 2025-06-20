//
//  NotebookAppApp.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//
import SwiftUI

@main
struct NotebookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            CategoryListView(context: persistenceController.container.viewContext)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
