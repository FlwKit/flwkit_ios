import Foundation

class Analytics {
    static let shared = Analytics()
    
    private var baseURL: String = "https://api.flwkit.com"
    private var appId: String?
    private var apiKey: String?
    private var userId: String?
    
    private var eventQueue: [AnalyticsEvent] = []
    private let queueLock = NSLock()
    private var isProcessing = false
    
    private let session: URLSession
    private let userDefaults = UserDefaults.standard
    private let queueKey = "flwkit_analytics_queue"
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        self.session = URLSession(configuration: config)
        loadQueue()
    }
    
    func configure(baseURL: String? = nil, appId: String, apiKey: String, userId: String? = nil) {
        self.appId = appId
        self.apiKey = apiKey
        self.userId = userId
        if let baseURL = baseURL {
            self.baseURL = baseURL
        }
    }
    
    /// Current user ID (for internal access)
    var currentUserId: String? {
        return userId
    }
    
    func track(_ eventName: String, properties: [String: Any] = [:]) {
        let event = AnalyticsEvent(
            name: eventName,
            properties: properties,
            timestamp: Date(),
            userId: userId
        )
        
        queueLock.lock()
        eventQueue.append(event)
        queueLock.unlock()
        
        saveQueue()
        processQueue()
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
        
        guard !events.isEmpty,
              let appId = appId,
              let apiKey = apiKey,
              let url = URL(string: "\(baseURL)/api/v1/analytics/events") else {
            // Re-add events to queue if we can't send
            queueLock.lock()
            eventQueue.insert(contentsOf: events, at: 0)
            isProcessing = false
            queueLock.unlock()
            saveQueue()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(appId, forHTTPHeaderField: "X-App-Id")
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let payload = ["events": events]
            request.httpBody = try encoder.encode(payload)
        } catch {
            print("FlwKit: Failed to encode analytics events - \(error)")
            // Re-add events to queue
            queueLock.lock()
            eventQueue.insert(contentsOf: events, at: 0)
            isProcessing = false
            queueLock.unlock()
            saveQueue()
            return
        }
        
        session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("FlwKit: Failed to send analytics events - \(error)")
                // Re-add events to queue for retry
                self.queueLock.lock()
                self.eventQueue.insert(contentsOf: events, at: 0)
                self.isProcessing = false
                self.queueLock.unlock()
                self.saveQueue()
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                // Re-add events to queue for retry
                self.queueLock.lock()
                self.eventQueue.insert(contentsOf: events, at: 0)
                self.isProcessing = false
                self.queueLock.unlock()
                self.saveQueue()
                return
            }
            
            // Success - continue processing queue
            self.queueLock.lock()
            self.isProcessing = false
            self.queueLock.unlock()
            
            // Process remaining events
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.processQueue()
            }
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
            eventQueue = try decoder.decode([AnalyticsEvent].self, from: data)
        } catch {
            print("FlwKit: Failed to load analytics queue - \(error)")
            eventQueue = []
        }
    }
}

struct AnalyticsEvent: Codable {
    let name: String
    let properties: [String: AnyCodable]
    let timestamp: Date
    let userId: String?
    
    init(name: String, properties: [String: Any], timestamp: Date, userId: String?) {
        self.name = name
        self.properties = properties.mapValues { AnyCodable($0) }
        self.timestamp = timestamp
        self.userId = userId
    }
}

