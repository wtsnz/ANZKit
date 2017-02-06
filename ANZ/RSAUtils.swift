//
//  RSAUtils.swift
//  ANZ
//
//  Created by Will Townsend on 2/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

class ANZRSAUtils {
    
    var publicKey, privateKey: SecKey?
    
    let tagPrivate = "com.anzkit.device.private"
    let tagPublic  = "com.anzkit.device.public"
    
    var keySourceStr = ""
    
    func getKeysFromKeychain() -> Bool {
        privateKey = getKeyTypeInKeyChain(tag: tagPrivate)
        publicKey = getKeyTypeInKeyChain(tag: tagPublic)
        return ((privateKey != nil)&&(publicKey != nil))
    }
    
    func keyTypeStr(tag: String) -> String {
        return tag.replacingOccurrences(of: "com.anzkit.device.", with: "")
    }
    
    func getKeyTypeInKeyChain(tag : String) -> SecKey? {
        
        let query: [String: Any] = [
            String(kSecClass)             : kSecClassKey,
            String(kSecAttrKeyType)       : kSecAttrKeyTypeRSA,
            String(kSecAttrApplicationTag): tag,
            String(kSecReturnRef)         : true
        ]
        
        var result : AnyObject?
        
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            print("\(keyTypeStr(tag: tag)) Key existed!")
            return result as! SecKey?
        }
        print("no \(keyTypeStr(tag: tag)) key")
        
        return nil
    }
    
    
    func generateKeyPair() -> (publicKey: SecKey?, privateKey: SecKey?) {
        
        // TODO: Check if keys already exist?
        
        let keySize = 2048
        
        var query: [String: Any] = [
            String(kSecAttrKeyType)       : kSecAttrKeyTypeRSA,
            String(kSecAttrKeySizeInBits) : keySize,
        ]
        
        query[String(kSecPrivateKeyAttrs)] = [
            String(kSecAttrIsPermanent)    : true,
            String(kSecAttrApplicationTag) : "sdsd"
        ]
        query[String(kSecPublicKeyAttrs)] = [
            String(kSecAttrIsPermanent)    : true,
            String(kSecAttrApplicationTag) : "asdsd"
        ]
        
        var privateKey: SecKey?
        var publicKey: SecKey?
        
        let status = SecKeyGeneratePair(query as CFDictionary, &publicKey, &privateKey)
        
        guard status == errSecSuccess else {
            print("Error")
            return (publicKey: nil, privateKey: nil)
        
        }
        
        self.storeInKeychain(tag: tagPublic, key: publicKey!)
        self.storeInKeychain(tag: tagPrivate, key: privateKey!)
        
        return (publicKey: publicKey, privateKey: privateKey)
    }
    
    //Store private and public keys in keychain
    
    func storeInKeychain(tag: String, key: SecKey) {
        
        let attribute = [
            String(kSecClass)              : kSecClassKey,
            String(kSecAttrKeyType)        : kSecAttrKeyTypeRSA,
            String(kSecValueRef)           : key,
            String(kSecAttrApplicationTag) : tag,
            String(kSecReturnPersistentRef): true
        ] as [String : Any]
        
        let status = SecItemAdd(attribute as CFDictionary, nil)
        
        if status != noErr {
            print("SecItemAdd Error!")
            return
        }
        
        print("\(keyTypeStr(tag: tag)) key added to keychain")
    }

    func getPublicKey(_ tag: String) -> Data? {
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecReturnData as String: true,
            kSecAttrApplicationTag as String: tagPublic,
        ]
        
        var result: AnyObject?
        let status = withUnsafeMutablePointer(to: &result) { SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0)) }
        
        if status == errSecSuccess {
            if let data = result as? Data {
                return data
            }
        } else {
            print(status)
        }
        
        return nil
    }
    
    func getPublicKeyDER(_ tag: String) -> Data? {
        
        guard let keyData = self.getPublicKey(tag) else {
            return nil
        }
        
//        let publicKeyData = SecKeyCopyExternalRepresentation(publicKey!, nil)! as Data
        return CryptoExportImportManager().exportPublicKeyToDER(keyData, keyType: kSecAttrKeyTypeRSA as String, keySize: 2048)
    }
    
    //Delete keys when required.
    func deleteAllKeysInKeyChain() {
        
        let query : [String: AnyObject] = [
            String(kSecClass)             : kSecClassKey
        ]
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecItemNotFound:
            print("No key in keychain")
        case noErr:
            print("All Keys Deleted!")
        default:
            print("SecItemDelete error! \(status.description)")
        }
    }
    
    
    func decryptBase64String(encryptedBase64String: String) -> String? {
        
        guard let encryptedData = Data(base64Encoded: encryptedBase64String) else {
            return nil
        }
        
        guard let privateKey = self.getKeyTypeInKeyChain(tag: self.tagPrivate) else {
            print("no private key")
            return nil
        }
        
        guard let data = self.decryptWithRSAKey(encryptedData, rsaKeyRef: privateKey, padding: SecPadding()) else {
            return nil
        }
        
        guard let string = String.init(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    func decryptData(encryptedData: Data) -> Data? {
        
        guard let privateKey = self.getKeyTypeInKeyChain(tag: self.tagPrivate) else {
            print("no private key")
            return nil
        }
        
        return self.decryptWithRSAKey(encryptedData, rsaKeyRef: privateKey, padding: SecPadding())
    }
    
    // Borrowed from https://github.com/btnguyen2k/swiftutils/blob/master/SwiftUtils/RSAUtils.swift
    
    /**
     * Decrypts data with a RSA key.
     *
     * - Parameter encryptedData: the data to be decrypted
     * - Parameter rsaKeyRef: the RSA key
     * - Parameter padding: padding used for decryption
     *
     * - Returns: the decrypted data
     */
    
     private func decryptWithRSAKey(_ encryptedData: Data, rsaKeyRef: SecKey, padding: SecPadding) -> Data? {
        let blockSize = SecKeyGetBlockSize(rsaKeyRef)
        let dataSize = encryptedData.count / MemoryLayout<UInt8>.size
        
        var encryptedDataAsArray = [UInt8](repeating: 0, count: dataSize)
        (encryptedData as NSData).getBytes(&encryptedDataAsArray, length: dataSize)
        
        var decryptedData = [UInt8](repeating: 0, count: 0)
        var idx = 0
        while (idx < encryptedDataAsArray.count ) {
            var idxEnd = idx + blockSize
            if ( idxEnd > encryptedDataAsArray.count ) {
                idxEnd = encryptedDataAsArray.count
            }
            var chunkData = [UInt8](repeating: 0, count: blockSize)
            for i in idx..<idxEnd {
                chunkData[i-idx] = encryptedDataAsArray[i]
            }
            
            var decryptedDataBuffer = [UInt8](repeating: 0, count: blockSize)
            var decryptedDataLength = blockSize
            
            let status = SecKeyDecrypt(rsaKeyRef, padding, chunkData, idxEnd-idx, &decryptedDataBuffer, &decryptedDataLength)
            if ( status != noErr ) {
                return nil
            }
            let finalData = removePadding(decryptedDataBuffer)
            decryptedData += finalData
            
            idx += blockSize
        }
        
        return Data(bytes: UnsafePointer<UInt8>(decryptedData), count: decryptedData.count)
    }
    
    private func removePadding(_ data: [UInt8]) -> [UInt8] {
        var idxFirstZero = -1
        var idxNextZero = data.count
        for i in 0..<data.count {
            if ( data[i] == 0 ) {
                if ( idxFirstZero < 0 ) {
                    idxFirstZero = i
                } else {
                    idxNextZero = i
                    break
                }
            }
        }
        if ( idxNextZero-idxFirstZero-1 == 0 ) {
            idxNextZero = idxFirstZero
            idxFirstZero = -1
        }
        var newData = [UInt8](repeating: 0, count: idxNextZero-idxFirstZero-1)
        for i in idxFirstZero+1..<idxNextZero {
            newData[i-idxFirstZero-1] = data[i]
        }
        return newData
    }
    
    
}
