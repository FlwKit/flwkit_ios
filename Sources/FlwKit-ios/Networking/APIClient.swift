import Foundation

class APIClient {
    static let shared = APIClient()
    
    private var baseURL: String = "https://api.flwkit.com"
    private var appId: String?
    private var apiKey: String?
    
    private let session: URLSession
    private let cache: FlowCache
    private let variantCache: VariantCache
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.cache = FlowCache.shared
        self.variantCache = VariantCache.shared
    }
    
    func configure(baseURL: String? = nil, appId: String, apiKey: String) {
        self.appId = appId
        self.apiKey = apiKey
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
    }
    
    func fetchFlow(userId: String? = nil, completion: @escaping (Result<Flow, Error>) -> Void) {
        guard let appId = appId, let apiKey = apiKey else {
            completion(.failure(FlwKitError.notConfigured))
            return
        }
        
        // Get session ID from analytics
        let analytics = Analytics.shared
        let sessionId = analytics.sessionId
        
        // First, fetch the flow to get the flowKey
        // Build URL: /sdk/v1/apps/:appId/flow
        var urlString = "\(baseURL)/sdk/v1/apps/\(appId)/flow"
        if let userId = userId {
            urlString += "?userId=\(userId)"
        }
        
        guard let url = URL(string: urlString) else {
            completion(.failure(FlwKitError.invalidURL))
            return
        }
        
        // Fetch flow first to get flowKey, then check for A/B test
        fetchFlowFromAPI(url: url, apiKey: apiKey, appId: appId) { [weak self] result in
            guard let self = self else {
                completion(.failure(FlwKitError.invalidResponse))
                return
            }
            
            switch result {
            case .success(let flow):
                // Now check for A/B test using the actual flowKey
                self.checkABTestVariant(flowKey: flow.flowKey, userId: userId, sessionId: sessionId) { abTestResult in
                    // Set flow context and A/B test context in analytics if A/B test is active
                    if let abTest = abTestResult, abTest.hasActiveTest {
                        // Use flowId from flow or testId from A/B test response
                        let flowIdToUse = abTest.testId ?? flow.id
                        if let flowVersionId = abTest.flowVersionId {
                            analytics.setFlowContext(flowId: flowIdToUse, flowVersionId: flowVersionId)
                        }
                        analytics.setABTestContext(testId: abTest.testId, variantId: abTest.variant?.id)
                    } else {
                        // Clear A/B test context if no active test
                        analytics.setABTestContext(testId: nil, variantId: nil)
                        // Set flow context without version (default published version)
                        analytics.setFlowContext(flowId: flow.id, flowVersionId: nil)
                    }
                    
                    // Return the flow (backend should have served the variant if A/B test is active)
                    completion(.success(flow))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /// Check for A/B test variant assignment
    func checkABTestVariant(flowKey: String, userId: String? = nil, sessionId: String? = nil, completion: @escaping (ABTestResponse?) -> Void) {
        guard let appId = appId, let apiKey = apiKey else {
            completion(nil as ABTestResponse?)
            return
        }
        
        // Check cache first
        if let cached = variantCache.get(flowKey: flowKey, userId: userId, sessionId: sessionId ?? "") {
            completion(cached)
            return
        }
        
        // Build URL: /sdk/v1/apps/:appId/ab-tests/:flowKey
        var components = URLComponents(string: "\(baseURL)/sdk/v1/apps/\(appId)/ab-tests/\(flowKey)")
        var queryItems: [URLQueryItem] = []
        
        if let userId = userId {
            queryItems.append(URLQueryItem(name: "userId", value: userId))
        }
        if let sessionId = sessionId {
            queryItems.append(URLQueryItem(name: "sessionId", value: sessionId))
        }
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            completion(nil as ABTestResponse?)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            // Handle errors gracefully - if A/B test check fails, continue without it
            if let error = error {
                #if DEBUG
                print("FlwKit A/B Test: Failed to check variant - \(error.localizedDescription)")
                #endif
                completion(nil as ABTestResponse?)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(nil as ABTestResponse?)
                return
            }
            
            // 404 is normal if no active test exists
            if httpResponse.statusCode == 404 {
                let noTestResponse = ABTestResponse(
                    hasActiveTest: false,
                    testId: nil,
                    testName: nil,
                    variant: nil,
                    flowVersionId: nil
                )
                completion(noTestResponse)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode), let data = data else {
                #if DEBUG
                print("FlwKit A/B Test: HTTP error \(httpResponse.statusCode)")
                #endif
                completion(nil as ABTestResponse?)
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let abTestResponse = try decoder.decode(ABTestResponse.self, from: data)
                
                // Cache the variant assignment
                self?.variantCache.set(
                    flowKey: flowKey,
                    variant: abTestResponse,
                    userId: userId,
                    sessionId: sessionId ?? ""
                )
                
                completion(abTestResponse)
            } catch {
                #if DEBUG
                print("FlwKit A/B Test: Failed to decode response - \(error)")
                #endif
                completion(nil)
            }
        }.resume()
    }
    
    private func fetchFlowFromAPI(url: URL, apiKey: String, appId: String, completion: @escaping (Result<Flow, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                // Try to use cached flow on network failure
                if let cachedFlow = self?.cache.getFlow(flowKey: appId) {
                    completion(.success(cachedFlow))
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(FlwKitError.invalidResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try cache on error
                if let cachedFlow = self?.cache.getFlow(flowKey: appId) {
                    completion(.success(cachedFlow))
                } else {
                    completion(.failure(FlwKitError.httpError(httpResponse.statusCode)))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(FlwKitError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                // Decode as FlowPayloadV1 first
                let payload = try decoder.decode(FlowPayloadV1.self, from: data)
                // Convert to Flow
                let flow = Flow(from: payload)
                
                // Cache using flowKey from response
                self?.cache.saveFlow(flow, for: flow.flowKey)
                // Also cache by appId for quick lookup
                self?.cache.saveFlow(flow, for: appId)
                
                // Register all themes from the response
                for theme in flow.themes {
                    ThemeManager.shared.registerTheme(theme)
                }
                
                completion(.success(flow))
            } catch {
                #if DEBUG
                print("FlwKit Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("Type mismatch: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .valueNotFound(let type, let context):
                        print("Value not found: Expected \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .keyNotFound(let key, let context):
                        print("Key not found: \(key.stringValue) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
                    case .dataCorrupted(let context):
                        print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: ".")) - \(context.debugDescription)")
                    @unknown default:
                        print("Unknown decoding error")
                    }
                }
                #endif
                completion(.failure(error))
            }
        }.resume()
    }
    
    // Note: Themes are now included in the flow response, so separate fetching is rarely needed
    // This method is kept for backwards compatibility or edge cases
    func fetchTheme(themeId: String, completion: @escaping (Result<Theme, Error>) -> Void) {
        // Check cache first
        if let cachedTheme = cache.getTheme(themeId: themeId) {
            completion(.success(cachedTheme))
            return
        }
        
        // Check if theme is already registered in ThemeManager
        let theme = ThemeManager.shared.getTheme(themeId: themeId)
        if theme.id != "default" {
            completion(.success(theme))
            return
        }
        
        guard let appId = appId, let apiKey = apiKey else {
            completion(.failure(FlwKitError.notConfigured))
            return
        }
        
        guard let url = URL(string: "\(baseURL)/sdk/v1/themes/\(themeId)") else {
            completion(.failure(FlwKitError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let data = data else {
                completion(.failure(FlwKitError.invalidResponse))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let theme = try decoder.decode(Theme.self, from: data)
                self?.cache.saveTheme(theme, for: themeId)
                ThemeManager.shared.registerTheme(theme)
                completion(.success(theme))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

// MARK: - Flow Cache

class FlowCache {
    static let shared = FlowCache()
    
    private let userDefaults = UserDefaults.standard
    private let flowKeyPrefix = "flwkit_flow_"
    private let themeKeyPrefix = "flwkit_theme_"
    
    private init() {}
    
    func saveFlow(_ flow: Flow, for flowKey: String) {
        let key = "\(flowKeyPrefix)\(flowKey)"
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(flow)
            userDefaults.set(data, forKey: key)
        } catch {
            print("FlwKit: Failed to cache flow - \(error)")
        }
    }
    
    func getFlow(flowKey: String) -> Flow? {
        let key = "\(flowKeyPrefix)\(flowKey)"
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Flow.self, from: data)
        } catch {
            print("FlwKit: Failed to decode cached flow - \(error)")
            return nil
        }
    }
    
    func saveTheme(_ theme: Theme, for themeId: String) {
        let key = "\(themeKeyPrefix)\(themeId)"
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(theme)
            userDefaults.set(data, forKey: key)
        } catch {
            print("FlwKit: Failed to cache theme - \(error)")
        }
    }
    
    func getTheme(themeId: String) -> Theme? {
        let key = "\(themeKeyPrefix)\(themeId)"
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(Theme.self, from: data)
        } catch {
            print("FlwKit: Failed to decode cached theme - \(error)")
            return nil
        }
    }
}

// MARK: - Variant Cache

class VariantCache {
    static let shared = VariantCache()
    
    /// Cached A/B test variant assignment
    private struct CachedVariant {
        let flowKey: String
        let variant: ABTestResponse
        let expiresAt: Date
        let userId: String?
        let sessionId: String
        
        var isExpired: Bool {
            return Date() > expiresAt
        }
    }
    
    private var cache: [String: CachedVariant] = [:]
    private let cacheLock = NSLock()
    private let cacheDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    private init() {}
    
    func getKey(flowKey: String, userId: String?, sessionId: String) -> String {
        return "\(flowKey):\(userId ?? sessionId)"
    }
    
    func get(flowKey: String, userId: String?, sessionId: String) -> ABTestResponse? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let key = getKey(flowKey: flowKey, userId: userId, sessionId: sessionId)
        guard let cached = cache[key] else {
            return nil
        }
        
        // Check expiration
        if cached.isExpired {
            cache.removeValue(forKey: key)
            return nil
        }
        
        // Check if user changed (userId takes priority)
        if let userId = userId, cached.userId != userId {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return cached.variant
    }
    
    func set(flowKey: String, variant: ABTestResponse, userId: String?, sessionId: String) {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        let key = getKey(flowKey: flowKey, userId: userId, sessionId: sessionId)
        let expiresAt = Date().addingTimeInterval(cacheDuration)
        
        cache[key] = CachedVariant(
            flowKey: flowKey,
            variant: variant,
            expiresAt: expiresAt,
            userId: userId,
            sessionId: sessionId
        )
    }
    
    func clear() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        cache.removeAll()
    }
}

// MARK: - Errors

enum FlwKitError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case noData
    case httpError(Int)
    case flowNotFound
    case themeNotFound
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "FlwKit is not configured. Call FlwKit.configure() first."
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .flowNotFound:
            return "Flow not found"
        case .themeNotFound:
            return "Theme not found"
        }
    }
}

