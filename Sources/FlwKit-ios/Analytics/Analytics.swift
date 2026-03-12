import Foundation

// MARK: - Analytics v2 (fixed schema for dashboard)

/// Valid Analytics v2 event types (do not add or rename without backend coordination)
enum AnalyticsV2EventType: String {
    case flow_started
    case screen_viewed
    case choice_selected
    case input_submitted
    case flow_completed
    case flow_abandoned
    case paywall_shown
    case paywall_converted
}

/// Single event for POST /sdk/v2/apps/:appId/analytics/events
struct AnalyticsV2EventPayload: Encodable {
    let event_type: String
    let metadata: AnalyticsV2Metadata
    let event_data: [String: AnyCodable]
    
    enum CodingKeys: String, CodingKey {
        case event_type
        case metadata
        case event_data
    }
}

struct AnalyticsV2Metadata: Encodable {
    let flow_id: String
    let timestamp: String
    var screen_id: String?
    var user_id: String?
    var anonymous_id: String?
    var variant_id: String?
    var app_version: String?
    var country: String?
    var device: String?
    
    enum CodingKeys: String, CodingKey {
        case flow_id, timestamp, screen_id, user_id, anonymous_id, variant_id, app_version, country, device
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(flow_id, forKey: .flow_id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encodeIfPresent(screen_id, forKey: .screen_id)
        try container.encodeIfPresent(user_id, forKey: .user_id)
        try container.encodeIfPresent(anonymous_id, forKey: .anonymous_id)
        try container.encodeIfPresent(variant_id, forKey: .variant_id)
        try container.encodeIfPresent(app_version, forKey: .app_version)
        try container.encodeIfPresent(country, forKey: .country)
        try container.encodeIfPresent(device, forKey: .device)
    }
}

/// Ingest API request body
struct AnalyticsV2IngestRequest: Encodable {
    let events: [AnalyticsV2EventPayload]
}

/// Ingest API success response
struct AnalyticsV2IngestResponse: Decodable {
    let accepted: Int
    let rejected: Int
    let invalidIndices: [Int]
}

/// Ingest API error response (400)
struct AnalyticsV2ErrorResponse: Decodable {
    let error: String?
    let invalidIndices: [Int]
}

class Analytics {
    static let shared = Analytics()
    
    private var baseURL: String = "https://api.flwkit.com"
    private var apiKey: String?
    private var appId: String?
    private var userId: String?
    private var flowId: String?
    private var flowVersionId: String?
    private var sessionId: String?
    private var abTestId: String?
    private var variantId: String?
    
    private var eventQueue: [AnalyticsEventPayload] = []
    private let queueLock = NSLock()
    private var isProcessing = false
    
    private var v2EventQueue: [AnalyticsV2EventPayload] = []
    private let v2QueueLock = NSLock()
    private var v2IsProcessing = false
    private var v2RetryCount = 0
    private let v2BatchSize = 20
    private let v2MaxRetries = 5
    
    private let session: URLSession
    private let userDefaults = UserDefaults.standard
    private let queueKey = "flwkit_analytics_queue"
    private let v2QueueKey = "flwkit_analytics_v2_queue"
    private let sessionIdKey = "flwkit_session_id"
    private let userIdKey = "flwkit_user_id"
    private let anonymousIdKey = "flwkit_anonymous_id"
    private let appIdKey = "flwkit_app_id"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.sessionId = getOrCreateSessionId()
        self.userId = loadUserId()
        self.appId = userDefaults.string(forKey: appIdKey)
        loadQueue()
    }
    
    func configure(baseURL: String? = nil, apiKey: String, userId: String? = nil) {
        self.apiKey = apiKey
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
        if let userId = userId {
            setUserId(userId)
        }
        if appId == nil {
            self.appId = userDefaults.string(forKey: appIdKey)
        }
        loadV2Queue()
    }
    
    /// Set app ID (called automatically when a flow is fetched and response includes appId)
    func setAppIdIfNeeded(_ appId: String?) {
        guard let appId = appId, !appId.isEmpty else { return }
        self.appId = appId
        userDefaults.set(appId, forKey: appIdKey)
    }
    
    /// Current user ID (for internal access)
    var currentUserId: String? {
        return userId
    }
    
    /// Current session ID (for internal access)
    var currentSessionId: String? {
        return sessionId ?? getOrCreateSessionId()
    }
    
    /// Current variant ID (for internal access)
    var currentVariantId: String? {
        return variantId
    }
    
    /// Set user ID for cross-session tracking
    func setUserId(_ userId: String) {
        self.userId = userId
        userDefaults.set(userId, forKey: userIdKey)
    }
    
    /// Set flow context for flow-specific events
    func setFlowContext(flowId: String, flowVersionId: String? = nil) {
        self.flowId = flowId
        self.flowVersionId = flowVersionId
    }
    
    /// Set A/B test context for events
    func setABTestContext(testId: String?, variantId: String?) {
        self.abTestId = testId
        self.variantId = variantId
    }
    
    /// Clear A/B test context (e.g., when flow ends)
    func clearABTestContext() {
        self.abTestId = nil
        self.variantId = nil
    }
    
    /// Get or create session ID
    private func getOrCreateSessionId() -> String {
        if let stored = userDefaults.string(forKey: sessionIdKey), !stored.isEmpty {
            return stored
        }
        
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let randomString = UUID().uuidString.prefix(9).replacingOccurrences(of: "-", with: "")
        let newSessionId = "session_\(timestamp)_\(randomString)"
        userDefaults.set(newSessionId, forKey: sessionIdKey)
        return newSessionId
    }
    
    /// Load user ID from storage
    private func loadUserId() -> String? {
        return userDefaults.string(forKey: userIdKey)
    }
    
    /// Reset session (creates new session ID)
    func resetSession() {
        sessionId = nil
        userDefaults.removeObject(forKey: sessionIdKey)
        sessionId = getOrCreateSessionId()
    }
    
    /// Generate a new session ID for flow start
    /// This should be called when a flow starts to ensure a fresh session ID
    func generateNewSessionId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let randomString = UUID().uuidString.prefix(9).replacingOccurrences(of: "-", with: "")
        let newSessionId = "session_\(timestamp)_\(randomString)"
        self.sessionId = newSessionId
        userDefaults.set(newSessionId, forKey: sessionIdKey)
        return newSessionId
    }
    
    /// Get or create anonymous ID for v2 attribution (persisted)
    private func getOrCreateAnonymousId() -> String {
        if let stored = userDefaults.string(forKey: anonymousIdKey), !stored.isEmpty {
            return stored
        }
        let newId = "anon_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16))"
        userDefaults.set(newId, forKey: anonymousIdKey)
        return newId
    }
    
    /// Build v2 metadata (flow_id and timestamp required; rest optional)
    private func buildV2Metadata(screenId: String? = nil) -> AnalyticsV2Metadata? {
        guard let flowId = flowId, !flowId.isEmpty else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(identifier: "UTC")
        let timestamp = formatter.string(from: Date())
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let country = Locale.current.region?.identifier
        return AnalyticsV2Metadata(
            flow_id: flowId,
            timestamp: timestamp,
            screen_id: screenId,
            user_id: userId,
            anonymous_id: userId == nil ? getOrCreateAnonymousId() : nil,
            variant_id: variantId,
            app_version: appVersion,
            country: country,
            device: "iOS"
        )
    }
    
    /// Enqueue and send a v2 event (only when appId and apiKey are set)
    func trackV2(eventType: AnalyticsV2EventType, screenId: String? = nil, eventData: [String: Any] = [:]) {
        guard let appId = appId, !appId.isEmpty, apiKey != nil else { return }
        guard let metadata = buildV2Metadata(screenId: screenId) else { return }
        let payload = AnalyticsV2EventPayload(
            event_type: eventType.rawValue,
            metadata: metadata,
            event_data: eventData.mapValues { AnyCodable($0) }
        )
        v2QueueLock.lock()
        v2EventQueue.append(payload)
        v2QueueLock.unlock()
        saveV2Queue()
        processV2Queue()
    }
    
    /// Track paywall shown (v2 only; call when your paywall is displayed)
    func trackPaywallShown(flowId: String, screenId: String? = nil) {
        let previousFlowId = self.flowId
        self.flowId = flowId
        trackV2(eventType: .paywall_shown, screenId: screenId, eventData: [:])
        if let previous = previousFlowId { self.flowId = previous }
    }
    
    /// Track paywall converted (v2 only; call when user converts at paywall)
    func trackPaywallConverted(flowId: String, screenId: String? = nil) {
        let previousFlowId = self.flowId
        self.flowId = flowId
        trackV2(eventType: .paywall_converted, screenId: screenId, eventData: [:])
        if let previous = previousFlowId { self.flowId = previous }
    }
    
    /// Track a generic event
    func trackEvent(eventType: String, eventData: [String: Any]) {
        guard apiKey != nil else {
            return
        }
        
        let payload = AnalyticsEventPayload(
            flowId: flowId,
            flowVersionId: flowVersionId,
            experimentId: abTestId, // Include experimentId at payload level
            variantId: variantId,  // Include variantId at payload level
            eventType: eventType,
            eventData: eventData,
            userId: userId,
            sessionId: sessionId ?? getOrCreateSessionId(),
            timestamp: Date()
        )
        
        queueLock.lock()
        eventQueue.append(payload)
        queueLock.unlock()
        
        saveQueue()
        processQueue()
    }
    
    /// Track flow start event
    func trackFlowStart(flowKey: String, entryScreenId: String) {
        trackEvent(eventType: "flow_start", eventData: [
            "flowKey": flowKey,
            "entryScreenId": entryScreenId
        ])
        trackV2(eventType: .flow_started, screenId: nil, eventData: [:])
    }
    
    /// Track flow complete event
    func trackFlowComplete(flowKey: String, totalScreens: Int, timeSpent: Int) {
        let formatter = ISO8601DateFormatter()
        trackEvent(eventType: "flow_complete", eventData: [
            "flowKey": flowKey,
            "completedAt": formatter.string(from: Date()),
            "totalScreens": totalScreens,
            "timeSpent": timeSpent
        ])
        trackV2(eventType: .flow_completed, screenId: nil, eventData: [:])
    }
    
    /// Track flow abandoned event
    func trackFlowAbandoned(flowKey: String, lastScreenId: String, screensCompleted: Int, timeSpent: Int) {
        trackEvent(eventType: "flow_abandoned", eventData: [
            "flowKey": flowKey,
            "lastScreenId": lastScreenId,
            "screensCompleted": screensCompleted,
            "timeSpent": timeSpent
        ])
        trackV2(eventType: .flow_abandoned, screenId: nil, eventData: [:])
    }
    
    /// Track screen view event
    func trackScreenView(screenId: String, screenName: String, screenIndex: Int, totalScreens: Int) {
        trackEvent(eventType: "screen_view", eventData: [
            "screenId": screenId,
            "screenName": screenName,
            "screenIndex": screenIndex,
            "totalScreens": totalScreens
        ])
        trackV2(eventType: .screen_viewed, screenId: screenId, eventData: [:])
    }
    
    /// Track screen enter event
    func trackScreenEnter(screenId: String, previousScreenId: String?, transition: String) {
        var eventData: [String: Any] = [
            "screenId": screenId,
            "transition": transition
        ]
        if let previousScreenId = previousScreenId {
            eventData["previousScreenId"] = previousScreenId
        }
        trackEvent(eventType: "screen_enter", eventData: eventData)
    }
    
    /// Track screen exit event
    func trackScreenExit(screenId: String, nextScreenId: String?, transition: String, timeSpent: Int) {
        var eventData: [String: Any] = [
            "screenId": screenId,
            "transition": transition,
            "timeSpent": timeSpent
        ]
        if let nextScreenId = nextScreenId {
            eventData["nextScreenId"] = nextScreenId
        }
        trackEvent(eventType: "screen_exit", eventData: eventData)
    }
    
    /// Track button click event
    func trackButtonClick(buttonId: String, buttonLabel: String, buttonAction: String, screenId: String) {
        trackEvent(eventType: "button_click", eventData: [
            "buttonId": buttonId,
            "buttonLabel": buttonLabel,
            "buttonAction": buttonAction,
            "screenId": screenId
        ])
    }
    
    /// Track choice selected event
    func trackChoiceSelected(choiceBlockId: String, optionValue: String, optionLabel: String, screenId: String, isMultiSelect: Bool) {
        trackEvent(eventType: "choice_selected", eventData: [
            "choiceBlockId": choiceBlockId,
            "optionValue": optionValue,
            "optionLabel": optionLabel,
            "screenId": screenId,
            "isMultiSelect": isMultiSelect
        ])
        trackV2(eventType: .choice_selected, screenId: screenId, eventData: [
            "choice_block_id": choiceBlockId,
            "option_value": optionValue,
            "option_label": optionLabel,
            "is_multi_select": isMultiSelect
        ])
    }
    
    /// Track text input submitted event
    func trackTextInputSubmitted(inputBlockId: String, inputKey: String, screenId: String, hasValue: Bool, valueLength: Int) {
        trackEvent(eventType: "text_input_submitted", eventData: [
            "inputBlockId": inputBlockId,
            "inputKey": inputKey,
            "screenId": screenId,
            "hasValue": hasValue,
            "valueLength": valueLength
        ])
        trackV2(eventType: .input_submitted, screenId: screenId, eventData: [
            "input_block_id": inputBlockId,
            "input_key": inputKey,
            "has_value": hasValue,
            "value_length": valueLength
        ])
    }
    
    /// Track form submitted event
    func trackFormSubmitted(screenId: String, fields: [String: Bool], completionRate: Double) {
        trackEvent(eventType: "form_submitted", eventData: [
            "screenId": screenId,
            "fields": fields,
            "completionRate": completionRate
        ])
    }
    
    /// Legacy method for backward compatibility
    func track(_ eventName: String, properties: [String: Any] = [:]) {
        trackEvent(eventType: eventName, eventData: properties)
    }
    
    private func processQueue() {
        queueLock.lock()
        guard !isProcessing, !eventQueue.isEmpty else {
            queueLock.unlock()
            return
        }
        isProcessing = true
        queueLock.unlock()
        
        sendEvents()
    }
    
    private func sendEvents() {
        queueLock.lock()
        guard !eventQueue.isEmpty else {
            isProcessing = false
        queueLock.unlock()
            return
        }
        
        guard let apiKey = apiKey else {
            isProcessing = false
            queueLock.unlock()
            return
        }
        
        // Take first event from queue
        let event = eventQueue.removeFirst()
        queueLock.unlock()
        
        // Send the event
        sendEvent(event, apiKey: apiKey) { [weak self] success in
            guard let self = self else { return }
            
            if !success {
                // Re-add event to front of queue on failure
                self.queueLock.lock()
                self.eventQueue.insert(event, at: 0)
                self.queueLock.unlock()
                self.saveQueue()
            }
            
            // Mark processing as complete and process next event
            self.queueLock.lock()
            self.isProcessing = false
            self.queueLock.unlock()
            
            // Process remaining events
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.processQueue()
            }
        }
    }
    
    private func sendEvent(_ event: AnalyticsEventPayload, apiKey: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/sdk/v1/events") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            request.httpBody = try encoder.encode(event)
        } catch {
            completion(false)
            return
        }
        
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false)
                return
            }
            
            // Accept 201 Created as success (per backend spec)
            if httpResponse.statusCode == 201 || (200...299).contains(httpResponse.statusCode) {
                completion(true)
            } else {
                // Handle specific error codes
                switch httpResponse.statusCode {
                case 400:
                    // Bad Request - invalid data, don't retry
                    completion(false) // Don't retry
                case 401:
                    // Unauthorized - invalid API key, don't retry
                    completion(false) // Don't retry
                case 429:
                    // Rate limited - queue for retry with backoff
                    completion(true) // Retry with backoff
                case 500...599:
                    // Server errors - retry
                    completion(true) // Retry
                default:
                    // Other errors - retry
                    completion(true) // Retry
                }
            }
        }.resume()
    }
    
    private func saveQueue() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(eventQueue)
            userDefaults.set(data, forKey: queueKey)
        } catch {
            // Failed to save queue
        }
    }
    
    private func loadQueue() {
        guard let data = userDefaults.data(forKey: queueKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            eventQueue = try decoder.decode([AnalyticsEventPayload].self, from: data)
        } catch {
            eventQueue = []
        }
    }
    
    // MARK: - Analytics v2 queue and ingest
    
    private func saveV2Queue() {
        v2QueueLock.lock()
        defer { v2QueueLock.unlock() }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(v2EventQueue)
            userDefaults.set(data, forKey: v2QueueKey)
        } catch {}
    }
    
    private func loadV2Queue() {
        guard let data = userDefaults.data(forKey: v2QueueKey) else { return }
        do {
            let decoder = JSONDecoder()
            v2EventQueue = try decoder.decode([AnalyticsV2EventPayload].self, from: data)
        } catch {
            v2EventQueue = []
        }
    }
    
    private func processV2Queue() {
        v2QueueLock.lock()
        guard !v2IsProcessing, !v2EventQueue.isEmpty, appId != nil, apiKey != nil else {
            v2QueueLock.unlock()
            return
        }
        let batchSize = min(v2BatchSize, v2EventQueue.count)
        let batch = Array(v2EventQueue.prefix(batchSize))
        v2EventQueue.removeFirst(batchSize)
        v2IsProcessing = true
        v2QueueLock.unlock()
        saveV2Queue()
        sendV2Batch(batch)
    }
    
    private func sendV2Batch(_ batch: [AnalyticsV2EventPayload]) {
        guard let appId = appId, let apiKey = apiKey,
              let url = URL(string: "\(baseURL)/sdk/v2/apps/\(appId)/analytics/events") else {
            v2QueueLock.lock()
            v2EventQueue.insert(contentsOf: batch, at: 0)
            v2IsProcessing = false
            v2QueueLock.unlock()
            saveV2Queue()
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = AnalyticsV2IngestRequest(events: batch)
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            v2QueueLock.lock()
            v2EventQueue.insert(contentsOf: batch, at: 0)
            v2IsProcessing = false
            v2QueueLock.unlock()
            saveV2Queue()
            return
        }
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            let httpResponse = response as? HTTPURLResponse
            let statusCode = httpResponse?.statusCode ?? -1
            if let error = error {
                self.v2Retry(batch: batch, retry: true)
                return
            }
            switch statusCode {
            case 200:
                if let data = data,
                   let decoded = try? JSONDecoder().decode(AnalyticsV2IngestResponse.self, from: data),
                   !decoded.invalidIndices.isEmpty {
                    let validIndices = Set(0..<batch.count).subtracting(decoded.invalidIndices)
                    let toRequeue = decoded.invalidIndices.sorted().map { batch[$0] }
                    self.v2QueueLock.lock()
                    self.v2EventQueue.insert(contentsOf: toRequeue, at: 0)
                    self.v2QueueLock.unlock()
                    self.saveV2Queue()
                }
                self.v2RetryCount = 0
                self.v2QueueLock.lock()
                self.v2IsProcessing = false
                self.v2QueueLock.unlock()
                DispatchQueue.main.async { self.processV2Queue() }
            case 400:
                if let data = data, let err = try? JSONDecoder().decode(AnalyticsV2ErrorResponse.self, from: data), !err.invalidIndices.isEmpty {
                    let toRequeue = err.invalidIndices.sorted().map { batch[$0] }
                    self.v2QueueLock.lock()
                    self.v2EventQueue.insert(contentsOf: toRequeue, at: 0)
                    self.v2QueueLock.unlock()
                    self.saveV2Queue()
                }
                self.v2RetryCount = 0
                self.v2QueueLock.lock()
                self.v2IsProcessing = false
                self.v2QueueLock.unlock()
                DispatchQueue.main.async { self.processV2Queue() }
            case 401, 403:
                self.v2QueueLock.lock()
                self.v2EventQueue.insert(contentsOf: batch, at: 0)
                self.v2IsProcessing = false
                self.v2QueueLock.unlock()
                self.saveV2Queue()
            case 429:
                self.v2Retry(batch: batch, retry: true)
            case 500...599:
                self.v2Retry(batch: batch, retry: true)
            default:
                self.v2Retry(batch: batch, retry: true)
            }
        }.resume()
    }
    
    private func v2Retry(batch: [AnalyticsV2EventPayload], retry: Bool) {
        v2QueueLock.lock()
        v2EventQueue.insert(contentsOf: batch, at: 0)
        v2IsProcessing = false
        v2QueueLock.unlock()
        saveV2Queue()
        guard retry, v2RetryCount < v2MaxRetries else {
            DispatchQueue.main.async { [weak self] in self?.processV2Queue() }
            return
        }
        v2RetryCount += 1
        let delay = min(2.0 * pow(2.0, Double(v2RetryCount)), 60.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.processV2Queue()
        }
    }
}

/// Analytics event payload matching backend specification
/// 
/// Critical Fields for Analytics Charts:
/// - flowId: Required for flow-level analytics (in payload, not eventData)
/// - flowVersionId: Required for version-specific analytics (in payload, not eventData)
/// - experimentId: Required for variant comparison charts (in payload, not eventData)
/// - variantId: Required for variant comparison charts (in payload, not eventData)
/// - sessionId: Required for session tracking and funnel analytics (in payload)
/// - eventData.screenId: Required for screen_view events (in eventData, not payload)
/// - timestamp: Required for accurate time series charts (ISO 8601 format)
struct AnalyticsEventPayload: Codable {
    let flowId: String?
    let flowVersionId: String?
    let experimentId: String? // Experiment ID for A/B testing (required for variant comparison charts)
    let variantId: String?    // Variant ID for A/B testing (required for variant comparison charts)
    let eventType: String
    let eventData: [String: AnyCodable] // Event-specific data (e.g., screenId for screen_view events)
    let userId: String?
    let sessionId: String // Required for session tracking and funnel analytics
    let timestamp: String // ISO 8601 string format (required for time series charts)
    
    enum CodingKeys: String, CodingKey {
        case flowId
        case flowVersionId
        case experimentId
        case variantId
        case eventType
        case eventData
        case userId
        case sessionId
        case timestamp
    }
    
    init(flowId: String?, flowVersionId: String?, experimentId: String?, variantId: String?, eventType: String, eventData: [String: Any], userId: String?, sessionId: String, timestamp: Date) {
        self.flowId = flowId
        self.flowVersionId = flowVersionId
        self.experimentId = experimentId
        self.variantId = variantId
        self.eventType = eventType
        self.eventData = eventData.mapValues { AnyCodable($0) }
        self.userId = userId
        self.sessionId = sessionId
        
        // Convert Date to ISO 8601 string (without fractional seconds for compatibility)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        self.timestamp = formatter.string(from: timestamp)
    }
    
    // Custom encoding to exclude nil optional values
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Only encode optional fields if they have values
        try container.encodeIfPresent(flowId, forKey: .flowId)
        try container.encodeIfPresent(flowVersionId, forKey: .flowVersionId)
        try container.encodeIfPresent(experimentId, forKey: .experimentId)
        try container.encodeIfPresent(variantId, forKey: .variantId)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(eventData, forKey: .eventData)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(timestamp, forKey: .timestamp)
    }
}
