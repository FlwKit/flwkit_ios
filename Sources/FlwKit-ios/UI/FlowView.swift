import SwiftUI

struct FlowView: View {
    let flow: Flow
    @State private var currentState: FlowState
    @State private var currentScreenIndex: Int = 0
    @State private var isLoading: Bool = false
    @State private var error: Error?
    
    let attributes: [String: Any]
    let onComplete: (([String: Any]) -> Void)?
    let onExit: (() -> Void)?
    
    private let stateManager = StateManager.shared
    private let analytics = Analytics.shared
    
    init(flow: Flow, flowKey: String, userId: String?, attributes: [String: Any], onComplete: (([String: Any]) -> Void)?, onExit: (() -> Void)?) {
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
        } else if let entryIndex = flow.screens.firstIndex(where: { $0.id == flow.entryScreenId }) {
            _currentScreenIndex = State(initialValue: entryIndex)
            initialState.currentScreenIndex = entryIndex
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
                .onAppear {
                    trackScreenView(screen: screen)
                }
            } else {
                // Flow complete
                Text("Flow Complete")
                    .onAppear {
                        handleFlowComplete()
                    }
            }
        }
        .onAppear {
            trackFlowStart()
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
        let finalAnswers = currentState.answers.mapValues { $0.value }
        analytics.track("flow_complete", properties: [
            "flowKey": currentState.flowKey,
            "answers": finalAnswers
        ])
        
        stateManager.clearState(for: currentState.flowKey, userId: currentState.userId)
        onComplete?(finalAnswers)
    }
    
    private func handleFlowExit() {
        analytics.track("flow_exit", properties: [
            "flowKey": currentState.flowKey,
            "screenId": flow.screens[currentScreenIndex].id
        ])
        
        onExit?()
    }
    
    private func trackFlowStart() {
        analytics.track("flow_start", properties: [
            "flowKey": currentState.flowKey,
            "flowId": flow.id,
            "version": flow.version
        ])
    }
    
    private func trackScreenView(screen: Screen) {
        analytics.track("screen_view", properties: [
            "flowKey": currentState.flowKey,
            "screenId": screen.id,
            "screenType": screen.type
        ])
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

