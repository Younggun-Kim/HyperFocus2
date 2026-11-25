import CoreNetwork
import Foundation
import os
import Security

/// 인증 토큰을 키체인에 저장한다. CoreNetwork의 `TokenManager`가 쓴다.
struct KeychainTokenStorage: TokenStorage {
    private struct StoredToken: Codable {
        let accessToken: String
        let refreshToken: String
        let tokenType: String
    }

    private let service: String
    private let account = "authToken"

    init(service: String = (Bundle.main.bundleIdentifier ?? "com.hyperfocus.timer") + ".auth") {
        self.service = service
    }

    func load() -> AuthToken? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            if status != errSecItemNotFound {
                Logger.data.error("토큰 읽기 실패: \(status)")
            }
            return nil
        }
        guard let stored = try? JSONDecoder().decode(StoredToken.self, from: data) else {
            Logger.data.error("저장된 토큰 형식이 다르다")
            return nil
        }
        return AuthToken(
            accessToken: stored.accessToken,
            refreshToken: stored.refreshToken,
            tokenType: stored.tokenType
        )
    }

    func save(_ token: AuthToken?) {
        SecItemDelete(baseQuery as CFDictionary)
        guard let token else { return }

        let stored = StoredToken(
            accessToken: token.accessToken,
            refreshToken: token.refreshToken,
            tokenType: token.tokenType
        )
        guard let data = try? JSONEncoder().encode(stored) else { return }

        var query = baseQuery
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            Logger.data.error("토큰 저장 실패: \(status)")
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
