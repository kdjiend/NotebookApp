//
//  NoteViewModel.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import Foundation
import SwiftUI
import Sodium // 确保这里导入 Sodium，因为 CryptoHelper 内部使用它
import CoreData

class NoteViewModel: ObservableObject {
    @Published var note: Note
    @Published var decryptedContent: String = ""
    @Published var errorMessage: String?

    private let context: NSManagedObjectContext

    init(note: Note, context: NSManagedObjectContext) {
        self.note = note
        self.context = context
    }

    func unlock(password: String) {
        // *** 关键：这里必须确保获取到 tag ***
        guard let encrypted = note.encryptedData, !encrypted.isEmpty,
              let salt = note.salt,
              let nonce = note.nonce,
              let tag = note.tag else { // 确保 tag 也被正确获取
            self.errorMessage = "笔记尚未加密或数据不完整，不能解锁。"
            return
        }

        do {
            // *** 关键：调用 CryptoHelper 进行解密 ***
            let decrypted = try CryptoHelper.decrypt(
                ciphertext: encrypted,
                salt: salt,
                nonce: nonce,
                tag: tag, // 传入 tag
                password: password
            )
            self.decryptedContent = String(data: decrypted, encoding: .utf8) ?? ""
            if self.decryptedContent.isEmpty && !encrypted.isEmpty {
                self.errorMessage = "解密内容为空，请检查。"
            } else {
                self.errorMessage = nil
            }
        } catch let error as CryptoHelper.CryptoError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "解密失败：\(error.localizedDescription)。密码可能不正确或数据已损坏。"
        }
    }

    func save(content: String, password: String) {
        guard let plaintextData = content.data(using: .utf8) else {
            self.errorMessage = "保存失败：无效内容编码。"
            return
        }

        do {
            // *** 关键：调用 CryptoHelper 进行加密，并获取返回的 tag ***
            let (ciphertext, salt, nonce, tag) = try CryptoHelper.encrypt(
                data: plaintextData,
                password: password
            )

            note.title = extractTitle(from: content)
            note.updatedAt = Date()
            note.salt = salt
            note.nonce = nonce
            note.encryptedData = ciphertext
            note.tag = tag // *** 关键：正确保存 CryptoHelper 返回的 tag ***

            try context.save()
            self.errorMessage = nil
        } catch let error as CryptoHelper.CryptoError {
            self.errorMessage = error.localizedDescription
        } catch {
            self.errorMessage = "保存失败：\(error.localizedDescription)。"
        }
    }

    private func extractTitle(from content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = trimmed.components(separatedBy: .newlines)
        return lines.first?.prefix(50).trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled Note"
    }
}
