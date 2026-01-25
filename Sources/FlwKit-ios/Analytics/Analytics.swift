import Foundation

class Analytics {
    static let shared = Analytics()
    
    private var baseURL: String = "https://api.flwkit.com"
    private var apiKey: String?
    private var userId: String?
    private var flowId: String?
    private var flowVersionId: String?
    private var sessionId: String?
    private var abTestId: String?
    private var variantId: String?
    
    private var eventQueue: [AnalyticsEventPayload] = []
    private let queueLock = NSLock()
    private var isProcessing = false
    
    private let session: URLSession
    private let userDefaults = UserDefaults.standard
    private let queueKey = "flwkit_analytics_queue"
    private let sessionIdKey = "flwkit_session_id"
    private let userIdKey = "flwkit_user_id"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        self.sessionId = getOrCreateSessionId()
        self.userId = loadUserId()
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
    }
    
    /// Track flow abandoned event
    func trackFlowAbandoned(flowKey: String, lastScreenId: String, screensCompleted: Int, timeSpent: Int) {
        trackEvent(eventType: "flow_abandoned", eventData: [
            "flowKey": flowKey,
            "lastScreenId": lastScreenId,
            "screensCompleted": screensCompleted,
            "timeSpent": timeSpent
        ])
    }
    
    /// Track screen view event
    func trackScreenView(screenId: String, screenName: String, screenIndex: Int, totalScreens: Int) {
        trackEvent(eventType: "screen_view", eventData: [
            "screenId": screenId,
            "screenName": screenName,
            "screenIndex": screenIndex,
            "totalScreens": totalScreens
        ])
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
