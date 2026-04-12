import Foundation

extension FlwKit {
    internal static var deviceID: String {
        let key = "flwkit_device_id"
        if let existing = UserDefaults.standard.string(forKey: key), !existing.isEmpty {
            return existing
        }

        let new = UUID().uuidString
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
        UserDefaults.standard.set(new, forKey: key)
        return new
    }

    public static func identify(userId: String) {
        UserDefaults.standard.set(userId, forKey: "flwkit_user_id")
    }

    internal static var assignmentID: String {
        return UserDefaults.standard.string(forKey: "flwkit_user_id") ?? deviceID
    }
}
