import Foundation

class Analytics {
    static let shared = Analytics()
    
    private var baseURL: String = "https://api.flwkit.com"
    private var apiKey: String?
    private var userId: String?
    private var flowId: String?
    private var flowVersionId: String?
    private var sessionId: String?
    
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
    
    func configure(baseURL: String? = nil, appId: String, apiKey: String, userId: String? = nil) {
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
    
    /// Get or create session ID
    private func getOrCreateSessionId() -> String {
        if let stored = userDefaults.string(forKey: sessionIdKey) {
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
        let payload = AnalyticsEventPayload(
            flowId: flowId,
            flowVersionId: flowVersionId,
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
        let events = eventQueue
        eventQueue.removeAll()
        queueLock.unlock()
        
        guard !events.isEmpty, let apiKey = apiKey else {
            // Re-add events to queue if we can't send
            queueLock.lock()
            eventQueue.insert(contentsOf: events, at: 0)
            isProcessing = false
            queueLock.unlock()
            saveQueue()
            return
        }
        
        // Send events individually (as per backend spec)
        for event in events {
            sendEvent(event, apiKey: apiKey)
        }
        
        // Mark processing as complete after all events are sent
        queueLock.lock()
        isProcessing = false
        queueLock.unlock()
        
        // Process remaining events if any were added during sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.processQueue()
        }
    }
    
    private func sendEvent(_ event: AnalyticsEventPayload, apiKey: String) {
        guard let url = URL(string: "\(baseURL)/sdk/v1/events") else {
            // Re-add event to queue
            queueLock.lock()
            eventQueue.append(event)
            queueLock.unlock()
            saveQueue()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(event)
        } catch {
            print("FlwKit: Failed to encode analytics event - \(error)")
            // Re-add event to queue
            queueLock.lock()
            eventQueue.append(event)
            queueLock.unlock()
            saveQueue()
            return
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("FlwKit: Failed to send analytics event - \(error)")
                // Re-add event to queue for retry
                self.queueLock.lock()
                self.eventQueue.append(event)
                self.queueLock.unlock()
                self.saveQueue()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                // Re-add event to queue
                self.queueLock.lock()
                self.eventQueue.append(event)
                self.queueLock.unlock()
                self.saveQueue()
                return
            }
            
            // Accept 201 Created as success (per backend spec)
            guard httpResponse.statusCode == 201 || (200...299).contains(httpResponse.statusCode) else {
                print("FlwKit: Failed to track event: HTTP \(httpResponse.statusCode)")
                // Re-add event to queue for retry (except for 400 Bad Request which is a client error)
                if httpResponse.statusCode != 400 {
                    self.queueLock.lock()
                    self.eventQueue.append(event)
                    self.queueLock.unlock()
                    self.saveQueue()
                }
                return
            }
            
            // Success - event was recorded
        }.resume()
    }
    
    private func saveQueue() {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(eventQueue)
            userDefaults.set(data, forKey: queueKey)
        } catch {
            print("FlwKit: Failed to save analytics queue - \(error)")
        }
    }
    
    private func loadQueue() {
        guard let data = userDefaults.data(forKey: queueKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            eventQueue = try decoder.decode([AnalyticsEventPayload].self, from: data)
        } catch {
            print("FlwKit: Failed to load analytics queue - \(error)")
            eventQueue = []
        }
    }
}

/// Analytics event payload matching backend specification
struct AnalyticsEventPayload: Codable {
    let flowId: String?
    let flowVersionId: String?
    let eventType: String
    let eventData: [String: AnyCodable]
    let userId: String?
    let sessionId: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case flowId
        case flowVersionId
        case eventType
        case eventData
        case userId
        case sessionId
        case timestamp
    }
    
    init(flowId: String?, flowVersionId: String?, eventType: String, eventData: [String: Any], userId: String?, sessionId: String, timestamp: Date) {
        self.flowId = flowId
        self.flowVersionId = flowVersionId
        self.eventType = eventType
        self.eventData = eventData.mapValues { AnyCodable($0) }
        self.userId = userId
        self.sessionId = sessionId
        self.timestamp = timestamp
    }
}
