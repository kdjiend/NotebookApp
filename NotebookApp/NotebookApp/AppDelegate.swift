//
//  AppDelegate.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("📘 NotebookApp 已启动")

        // 设置主窗口大小（如果需要）
        if let window = NSApplication.shared.windows.first {
            self.window = window
            window.setContentSize(NSSize(width: 800, height: 600))
            window.title = "NotebookApp"
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("📕 NotebookApp 即将退出")
    }

    // 可选：处理自定义 URL Scheme
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            print("收到 URL: \(url)")
            // 可根据 URL 执行操作
        }
    }
}
