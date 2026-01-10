import Foundation

class StateManager {
    static let shared = StateManager()
    
    private let userDefaults = UserDefaults.standard
    private let stateKeyPrefix = "flwkit_state_"
    
    private init() {}
    
    func saveState(_ state: FlowState, for flowKey: String, userId: String?) {
        let key = stateKey(for: flowKey, userId: userId)
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(state)
            userDefaults.set(data, forKey: key)
        } catch {
            print("FlwKit: Failed to save state - \(error)")
        }
    }
    
    func loadState(for flowKey: String, userId: String?) -> FlowState? {
        let key = stateKey(for: flowKey, userId: userId)
        
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(FlowState.self, from: data)
        } catch {
            print("FlwKit: Failed to load state - \(error)")
            return nil
        }
    }
    
    func clearState(for flowKey: String, userId: String?) {
        let key = stateKey(for: flowKey, userId: userId)
        userDefaults.removeObject(forKey: key)
    }
    
    private func stateKey(for flowKey: String, userId: String?) -> String {
        if let userId = userId {
            return "\(stateKeyPrefix)\(flowKey)_\(userId)"
        }
        return "\(stateKeyPrefix)\(flowKey)"
    }
}

