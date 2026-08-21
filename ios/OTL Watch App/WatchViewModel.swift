//
//  WatchViewModel.swift
//  OTL Watch App
//
//  Created by Soongyu Kwon on 11/8/23.
//

import Combine
import Foundation
import Security
import WatchConnectivity

struct WatchTokenPair: Codable, Equatable {
    let accessToken: String

    var isValid: Bool {
        !accessToken.isEmpty
    }
}

enum WatchTokenVault {
    static let service = "org.sparcs.otlplus.token-vault"
    static let account = "token-pair"

    static var hasTokenPair: Bool {
        do {
            return try read() != nil
        } catch {
            return false
        }
    }

    static func read() throws -> WatchTokenPair? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw WatchTokenVaultError.keychain(status)
        }

        let pair = try JSONDecoder().decode(WatchTokenPair.self, from: data)
        guard pair.isValid else {
            throw WatchTokenVaultError.invalidTokenPair
        }
        if let legacy = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           legacy["refreshToken"] != nil {
            try write(pair)
        }
        return pair
    }

    fileprivate static func write(_ pair: WatchTokenPair) throws {
        guard pair.isValid else {
            throw WatchTokenVaultError.invalidTokenPair
        }

        let data = try JSONEncoder().encode(pair)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw WatchTokenVaultError.keychain(updateStatus)
        }

        var item = baseQuery
        attributes.forEach { item[$0.key] = $0.value }
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }
        if addStatus == errSecDuplicateItem {
            let retryStatus = SecItemUpdate(
                baseQuery as CFDictionary,
                attributes as CFDictionary
            )
            guard retryStatus == errSecSuccess else {
                throw WatchTokenVaultError.keychain(retryStatus)
            }
            return
        }
        throw WatchTokenVaultError.keychain(addStatus)
    }

    fileprivate static func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw WatchTokenVaultError.keychain(status)
        }
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}

enum WatchTokenVaultError: Error {
    case invalidTokenPair
    case keychain(OSStatus)
}

@available(watchOS 6.0, *)
class WatchViewModel: NSObject, ObservableObject {
    static let shared = WatchViewModel()

    let session: WCSession
    @Published private(set) var tokenPair: WatchTokenPair?
    @Published private(set) var userID: String

    private override init() {
        session = .default
        tokenPair = try? WatchTokenVault.read()
        userID = UserDefaults.standard.string(forKey: "userID") ?? ""
        super.init()
        session.delegate = self
        session.activate()
    }

    private func apply(_ context: [String: Any]) {
        guard let method = context["method"] as? String else {
            return
        }

        switch method {
        case "tokenPair":
            guard let accessToken = context["accessToken"] as? String else {
                return
            }
            let pair = WatchTokenPair(accessToken: accessToken)
            guard pair.isValid else {
                return
            }
            do {
                try WatchTokenVault.write(pair)
            } catch {
                return
            }
            if let userID = context["userID"] as? String {
                storeUserID(userID)
            }
            DispatchQueue.main.async {
                self.tokenPair = pair
            }
        case "clearTokenPair":
            do {
                try WatchTokenVault.clear()
            } catch {
                return
            }
            storeUserID(context["userID"] as? String ?? "")
            DispatchQueue.main.async {
                self.tokenPair = nil
            }
        case "userID", "sendUserID":
            guard let userID = context["data"] as? String else {
                return
            }
            storeUserID(userID)
        default:
            return
        }
    }

    func invalidateSession() {
        do {
            try WatchTokenVault.clear()
        } catch {
            return
        }
        DispatchQueue.main.async {
            self.tokenPair = nil
        }
    }

    private func storeUserID(_ userID: String) {
        if userID.isEmpty {
            UserDefaults.standard.removeObject(forKey: "userID")
        } else {
            UserDefaults.standard.set(userID, forKey: "userID")
        }
        DispatchQueue.main.async {
            self.userID = userID
        }
    }
}

@available(watchOS 6.0, *)
extension WatchViewModel: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        guard activationState == .activated else {
            return
        }
        let context = session.receivedApplicationContext
        if !context.isEmpty {
            apply(context)
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        apply(applicationContext)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        apply(userInfo)
    }
}
