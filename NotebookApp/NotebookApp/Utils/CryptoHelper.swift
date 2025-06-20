//
//  CryptoHelper.swift
//  NotebookApp
//
//  Created by Irui Li on 2025/6/19.
//

import Foundation
import CryptoKit // 使用 CryptoKit 进行 AES-GCM
import Sodium    // 使用 Sodium 进行 Argon2id 密钥派生和随机数生成

struct CryptoHelper {
    static let sodium = Sodium()

    /// 生成 16 字节的随机 Salt
    static func generateSalt() -> Data {
        guard let bytes = sodium.randomBytes.buf(length: 16) else {
            fatalError("Failed to generate salt") // 在实际应用中，应进行更温和的错误处理
        }
        return Data(bytes)
    }

    /// 使用 Argon2id 从密码和 Salt 派生出 32 字节 (256 位) 的对称密钥
    static func deriveKey(password: String, salt: Data) -> SymmetricKey? {
        // Sodium 的 pwHash.hash 返回 [UInt8]
        guard let keyBytes = sodium.pwHash.hash(
            outputLength: 32, // 32 字节用于 AES-256
            passwd: Array(password.utf8),
            salt: Array(salt),
            opsLimit: sodium.pwHash.OpsLimitModerate, // 可以根据需求调整强度
            memLimit: sodium.pwHash.MemLimitModerate  // 可以根据需求调整强度
        ) else {
            return nil // 密钥派生失败，返回 nil
        }
        return SymmetricKey(data: Data(keyBytes))
    }

    /// 生成 12 字节的随机 Nonce (初始化向量 IV)
    static func generateNonce() -> Data? {
        guard let nonceBytes = sodium.randomBytes.buf(length: 12) else { // AES-GCM 需要 12 字节的 Nonce
            return nil // Nonce 生成失败，返回 nil
        }
        return Data(nonceBytes)
    }

    /// 使用 AES-256-GCM 加密数据
    /// - Parameters:
    ///   - data: 要加密的原始数据 (例如：笔记内容)
    ///   - password: 用户输入的密码
    /// - Returns: 包含密文、Salt、Nonce 和 Tag 的元组
    /// - Throws: 如果加密失败则抛出错误
    static func encrypt(data: Data, password: String) throws -> (ciphertext: Data, salt: Data, nonce: Data, tag: Data) {
        let salt = generateSalt()
        guard let key = deriveKey(password: password, salt: salt) else {
            throw CryptoError.keyDerivationFailed
        }
        guard let nonceData = generateNonce(),
              let nonce = try? AES.GCM.Nonce(data: nonceData) else {
            throw CryptoError.nonceGenerationFailed
        }

        // 使用 CryptoKit 进行加密
        let sealedBox = try AES.GCM.seal(data, using: key, nonce: nonce)

        // 确保 tag 被正确获取并返回
        return (sealedBox.ciphertext, salt, nonceData, sealedBox.tag)
    }

    /// 使用 AES-256-GCM 解密数据
    /// - Parameters:
    ///   - ciphertext: 密文数据
    ///   - salt: 用于密钥派生的 Salt
    ///   - nonce: 加密时使用的 Nonce
    ///   - tag: GCM 认证标签
    ///   - password: 用户输入的密码
    /// - Returns: 解密后的原始数据
    /// - Throws: 如果解密失败 (例如密码错误、数据篡改) 则抛出错误
    static func decrypt(ciphertext: Data, salt: Data, nonce: Data, tag: Data, password: String) throws -> Data {
        guard let key = deriveKey(password: password, salt: salt) else {
            throw CryptoError.keyDerivationFailed
        }
        guard let aesGCMNonce = try? AES.GCM.Nonce(data: nonce) else {
            throw CryptoError.invalidNonce
        }

        // 构造 SealedBox
        let sealedBox = try AES.GCM.SealedBox(
            nonce: aesGCMNonce,
            ciphertext: ciphertext,
            tag: tag
        )

        // 使用 CryptoKit 进行解密
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        return decryptedData
    }

    enum CryptoError: Error, LocalizedError {
        case keyDerivationFailed
        case nonceGenerationFailed
        case invalidNonce
        case decryptionFailed(Error)
        case encryptionFailed(Error)

        var errorDescription: String? {
            switch self {
            case .keyDerivationFailed:
                return "密钥派生失败，请检查密码或重试。"
            case .nonceGenerationFailed:
                return "随机数生成失败，请重试。"
            case .invalidNonce:
                return "无效的初始化向量 (Nonce)。"
            case .decryptionFailed(let error):
                return "解密失败：\(error.localizedDescription)。密码可能不正确或数据已损坏。"
            case .encryptionFailed(let error):
                return "加密失败：\(error.localizedDescription)。"
            }
        }
    }
}
