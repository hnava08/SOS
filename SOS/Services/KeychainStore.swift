import Foundation
import Security

enum KeychainStore {
    private static let authService = "com.santacruz.SOS.auth"
    private static let dataService = "com.santacruz.SOS.secure"

    // MARK: - Passwords

    static func savePassword(_ password: String, account: String) throws {
        try saveData(Data(password.utf8), account: account, service: authService)
    }

    static func readPassword(account: String) throws -> String {
        let data = try readData(account: account, service: authService)
        guard let password = String(data: data, encoding: .utf8) else {
            throw AuthError.invalidCredentials
        }
        return password
    }

    static func deletePassword(account: String) {
        deleteItem(account: account, service: authService)
    }

    // MARK: - Generic sensitive blobs

    static func saveSecureData(_ data: Data, account: String) throws {
        try saveData(data, account: account, service: dataService)
    }

    static func readSecureData(account: String) -> Data? {
        try? readData(account: account, service: dataService)
    }

    static func deleteSecureData(account: String) {
        deleteItem(account: account, service: dataService)
    }

    static func saveSecureString(_ value: String, account: String) throws {
        try saveSecureData(Data(value.utf8), account: account)
    }

    static func readSecureString(account: String) -> String? {
        guard let data = readSecureData(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Private

    private static func saveData(_ data: Data, account: String, service: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)

        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let status = SecItemAdd(add as CFDictionary, nil)
        guard status == errSecSuccess else { throw AuthError.keychainFailure }
    }

    private static func readData(account: String, service: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            throw AuthError.invalidCredentials
        }
        return data
    }

    private static func deleteItem(account: String, service: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
        SecItemDelete(query as CFDictionary)
    }
}
