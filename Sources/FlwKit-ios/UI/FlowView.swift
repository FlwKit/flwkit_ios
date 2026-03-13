import SwiftUI

struct FlowView: View {
    let flow: Flow
    @State private var currentState: FlowState
    @State private var currentScreenIndex: Int = 0
    @State private var isLoading: Bool = false
    @State private var error: Error?
    @State private var flowStartTime: Date?
    @State private var screenEnterTime: Date?
    @State private var hasTrackedFlowStart: Bool = false
    @State private var lastTrackedScreenId: String?
    @State private var hasCompletedFlow: Bool = false
    
    let attributes: [String: Any]
    let onComplete: ((FlwKitCompletionResult) -> Void)?
    let onExit: (() -> Void)?
    
    private let stateManager = StateManager.shared
    private let analytics = Analytics.shared
    
    init(flow: Flow, flowKey: String, userId: String?, attributes: [String: Any], onComplete: ((FlwKitCompletionResult) -> Void)?, onExit: (() -> Void)?) {
        self.flow = flow
        self.attributes = attributes
        
        // Initialize or restore state
        var initialState = stateManager.loadState(for: flowKey, userId: userId) ?? FlowState(
            flowKey: flowKey,
            userId: userId,
            answers: [:],
            attributes: attributes.mapValues { AnyCodable($0) },
            totalScreens: flow.screens.count
        )
        
        // Set attributes and totalScreens
        initialState.attributes = attributes.mapValues { AnyCodable($0) }
        initialState.totalScreens = flow.screens.count
        
        _currentState = State(initialValue: initialState)
        
        // Restore screen position or start at entry screen
        if let currentScreenId = initialState.currentScreenId,
           let index = flow.screens.firstIndex(where: { $0.id == currentScreenId }) {
            _currentScreenIndex = State(initialValue: index)
            initialState.currentScreenIndex = index
            initialState.currentScreenId = currentScreenId
        } else if let entryIndex = flow.screens.firstIndex(where: { $0.id == flow.entryScreenId }) {
            _currentScreenIndex = State(initialValue: entryIndex)
            initialState.currentScreenIndex = entryIndex
            initialState.currentScreenId = flow.screens[entryIndex].id
        }
        
        self.onComplete = onComplete
        self.onExit = onExit
    }
    
    var body: some View {
        ZStack {
            if let error = error {
                ErrorView(error: error) {
                    self.error = nil
                }
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if currentScreenIndex < flow.screens.count {
                let screen = flow.screens[currentScreenIndex]
                let theme = ThemeManager.shared.resolveTheme(for: screen, flowDefaultThemeId: flow.defaultThemeId)
                
                ScreenView(
                    screen: screen,
                    theme: theme,
                    state: $currentState,
                    onAnswer: handleAnswer,
                    onAction: handleAction
                )
                .id(screen.id)
                .onAppear {
                    handleScreenDisplayed(screen)
                }
            } else {
                // Flow complete
                Text("Flow Complete")
                    .onAppear {
                        handleFlowComplete()
                    }
            }
        }
    }
    
    private func handleAnswer(key: String, value: Any) {
        currentState.answers[key] = AnyCodable(value)
        saveState()
        
        // Track answer event
        analytics.track("answer", properties: [
            "flowKey": currentState.flowKey,
            "screenId": flow.screens[currentScreenIndex].id,
            "key": key,
            "value": String(describing: value)
        ])
    }
    
    private func handleAction(action: String, target: String?) {
        switch action {
        case "next":
            moveToNextScreen(target: target)
        case "back":
            moveToPreviousScreen()
        case "skip":
            moveToNextScreen(target: target)
        case "complete":
            handleFlowComplete()
        case "exit":
            handleFlowExit()
        default:
            if let target = target {
                moveToScreen(target: target)
            } else {
                moveToNextScreen(target: nil)
            }
        }
    }
    
    private func moveToNextScreen(target: String?) {
        if let target = target {
            moveToScreen(target: target)
        } else if currentScreenIndex < flow.screens.count - 1 {
            currentScreenIndex += 1
            currentState.currentScreenId = flow.screens[currentScreenIndex].id
            currentState.currentScreenIndex = currentScreenIndex
            saveState()
        } else {
            handleFlowComplete()
        }
    }
    
    private func moveToPreviousScreen() {
        if currentScreenIndex > 0 {
            currentScreenIndex -= 1
            currentState.currentScreenId = flow.screens[currentScreenIndex].id
            currentState.currentScreenIndex = currentScreenIndex
            saveState()
        }
    }
    
    private func moveToScreen(target: String) {
        if let index = flow.screens.firstIndex(where: { $0.id == target }) {
            currentScreenIndex = index
            currentState.currentScreenId = flow.screens[index].id
            currentState.currentScreenIndex = index
            saveState()
        }
    }
    
    private func handleFlowComplete() {
        guard !hasCompletedFlow else { return }
        hasCompletedFlow = true
        
        let rawAnswers = currentState.answers.mapValues { $0.value }
        // Map choice option IDs to labels and order by screen sequence
        let finalAnswers = mapAnswersToContentOrdered(rawAnswers)
        let timeSpent = flowStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0
        let completedAt = Date()
        
        analytics.trackFlowComplete(
            flowKey: currentState.flowKey,
            totalScreens: flow.screens.count,
            timeSpent: timeSpent
        )
        
        // Get variantId from analytics context before clearing it
        let variantId = analytics.currentVariantId
        
        stateManager.clearState(for: currentState.flowKey, userId: currentState.userId)
        analytics.resetSession() // Reset session on flow complete
        analytics.clearABTestContext() // Clear experiment context when flow ends
        
        // Create completion result with metadata
        let result = FlwKitCompletionResult(
            flowId: flow.id,
            variantId: variantId,
            completedAt: completedAt,
            answers: finalAnswers
        )
        
        onComplete?(result)
    }
    
    /// Maps answer IDs to actual content (labels) for choice blocks
    /// Orders answers by screen sequence to match the flow order
    /// For choice blocks, converts option values (IDs) to option labels (text)
    /// For other blocks (text input, slider), returns the value as-is
    private func mapAnswersToContentOrdered(_ answers: [String: Any]) -> [String: Any] {
        var mappedAnswers: [String: Any] = [:]
        
        // Build a map of block keys to their blocks for quick lookup
        var blockMap: [String: Block] = [:]
        for screen in flow.screens {
            for block in screen.blocks {
                if let blockKey = block.key {
                    blockMap[blockKey] = block
                }
            }
        }
        
        // Iterate through screens in order to preserve answer sequence
        // Note: If backend sends screens in reverse, we may need to reverse here
        // but keep screens array as-is for navigation to work correctly
        for screen in flow.screens {
            for block in screen.blocks {
                guard let blockKey = block.key,
                      let rawValue = answers[blockKey] else {
                    continue
                }
                
                // Check if this is a choice block
                if block.type == "choice", let options = block.options {
                    // Create a map of option values to labels
                    let optionMap: [String: String] = Dictionary(uniqueKeysWithValues: options.map { ($0.value, $0.label) })
                    
                    // Map the answer value(s)
                    if let singleValue = rawValue as? String {
                        // Single select: map the option value to label
                        mappedAnswers[blockKey] = optionMap[singleValue] ?? singleValue
                    } else if let arrayValue = rawValue as? [String] {
                        // Multi-select: map each option value to label
                        mappedAnswers[blockKey] = arrayValue.map { optionMap[$0] ?? $0 }
                    } else {
                        // Unknown format, keep original
                        mappedAnswers[blockKey] = rawValue
                    }
                } else {
                    // Not a choice block, keep original value (text input, slider, etc.)
                    mappedAnswers[blockKey] = rawValue
                }
            }
        }
        
        // Add any answers that weren't found in the flow (edge case)
        for (key, value) in answers {
            if mappedAnswers[key] == nil {
                mappedAnswers[key] = value
            }
        }
        
        return mappedAnswers
    }
    
    private func handleFlowExit() {
        let timeSpent = flowStartTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0
        let screensCompleted = currentScreenIndex + 1
        
        analytics.trackFlowAbandoned(
            flowKey: currentState.flowKey,
            lastScreenId: flow.screens[currentScreenIndex].id,
            screensCompleted: screensCompleted,
            timeSpent: timeSpent
        )
        
        analytics.clearABTestContext() // Clear experiment context when flow is abandoned
        
        onExit?()
    }
    
    private func trackFlowStart() {
        flowStartTime = Date()
        
        // Generate a new session ID for this flow (critical for screen analytics)
        _ = analytics.generateNewSessionId()
        
        // Set flow context for analytics
        analytics.setFlowContext(flowId: flow.id, flowVersionId: "\(flow.version)")
        
        // Track flow start event
        analytics.trackFlowStart(
            flowKey: currentState.flowKey,
            entryScreenId: flow.entryScreenId
        )
    }
    
    private func trackScreenView(screen: Screen) {
        // Generate screen name: use screen type or fallback to "Screen {index}"
        let screenName: String = {
            // Try to get name from screen blocks (header block title)
            if let headerBlock = screen.blocks.first(where: { $0.type == "header" }),
               let title = headerBlock.title {
                return title
            }
            // Fallback to screen type or generic name
            return screen.type.capitalized.isEmpty ? "Screen \(currentScreenIndex + 1)" : screen.type.capitalized
        }()
        
        // Track screen view with all required fields
        analytics.trackScreenView(
            screenId: screen.id,                    // REQUIRED: Exact screen ID from flow data
            screenName: screenName,                  // REQUIRED: Human-readable name
            screenIndex: currentScreenIndex,         // RECOMMENDED: Position in flow
            totalScreens: flow.screens.count         // RECOMMENDED: Total screens
        )
    }
    
    private func handleScreenDisplayed(_ screen: Screen) {
        currentState.currentScreenId = screen.id
        currentState.currentScreenIndex = currentScreenIndex
        
        // Track flow_start before the first screen_view.
        if !hasTrackedFlowStart {
            trackFlowStart()
            hasTrackedFlowStart = true
        }
        
        guard lastTrackedScreenId != screen.id else { return }
        
        // Force one screen_view per visible screen change.
        trackScreenView(screen: screen)
        lastTrackedScreenId = screen.id
        screenEnterTime = Date()
        saveState()
    }
    
    private func saveState() {
        stateManager.saveState(currentState, for: currentState.flowKey, userId: currentState.userId)
    }
}

struct ErrorView: View {
    let error: Error
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry", action: onRetry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

