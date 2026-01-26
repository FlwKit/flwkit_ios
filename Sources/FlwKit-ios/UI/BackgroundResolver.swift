import SwiftUI

// MARK: - Background Configuration

enum BackgroundType {
    case solid(color: Color, opacity: Double)
    case gradient(startColor: Color, startOpacity: Double, endColor: Color, endOpacity: Double, angle: Double)
}

struct BackgroundConfig {
    let type: BackgroundType
}

// MARK: - Background Resolution

struct BackgroundResolver {
    /// Resolve background configuration with priority: screen override → theme default
    static func resolveBackground(screen: Screen, theme: Theme) -> BackgroundConfig {
        // Priority 1: Screen gradient override
        if screen.backgroundType == "gradient",
           let startColor = screen.gradientStartColor,
           let endColor = screen.gradientEndColor {
            return BackgroundConfig(
                type: .gradient(
                    startColor: Color(hex: startColor),
                    startOpacity: screen.gradientStartOpacity ?? 100.0,
                    endColor: Color(hex: endColor),
                    endOpacity: screen.gradientEndOpacity ?? 100.0,
                    angle: screen.gradientAngle ?? 180.0
                )
            )
        }
        
        // Priority 2: Screen solid override
        if let backgroundColor = screen.backgroundColor {
            return BackgroundConfig(
                type: .solid(
                    color: Color(hex: backgroundColor),
                    opacity: screen.backgroundOpacity ?? 100.0
                )
            )
        }
        
        // Priority 3: Screen wants solid but no color specified, use theme
        if screen.backgroundType == "solid" {
            return BackgroundConfig(
                type: .solid(
                    color: Color(hex: theme.tokens.background),
                    opacity: 100.0
                )
            )
        }
        
        // Priority 4: Theme gradient
        if theme.backgroundType == "gradient",
           let startColor = theme.gradientStartColor,
           let endColor = theme.gradientEndColor {
            return BackgroundConfig(
                type: .gradient(
                    startColor: Color(hex: startColor),
                    startOpacity: theme.gradientStartOpacity ?? 100.0,
                    endColor: Color(hex: endColor),
                    endOpacity: theme.gradientEndOpacity ?? 100.0,
                    angle: theme.gradientAngle ?? 180.0
                )
            )
        }
        
        // Priority 5: Default - theme solid background
        return BackgroundConfig(
            type: .solid(
                color: Color(hex: theme.tokens.background),
                opacity: 100.0
            )
        )
    }
}

// MARK: - Background View

struct BackgroundView: View {
    let config: BackgroundConfig
    
    var body: some View {
        switch config.type {
        case .solid(let color, let opacity):
            color.opacity(opacity / 100.0)
            
        case .gradient(let startColor, let startOpacity, let endColor, let endOpacity, let angle):
            LinearGradient(
                gradient: Gradient(colors: [
                    startColor.opacity(startOpacity / 100.0),
                    endColor.opacity(endOpacity / 100.0)
                ]),
                startPoint: getStartPoint(angle: angle),
                endPoint: getEndPoint(angle: angle)
            )
        }
    }
    
    private func getStartPoint(angle: Double) -> UnitPoint {
        let radians = angle * .pi / 180.0
        let x = 0.5 - sin(radians) * 0.5
        let y = 0.5 + cos(radians) * 0.5
        return UnitPoint(x: x, y: y)
    }
    
    private func getEndPoint(angle: Double) -> UnitPoint {
        let radians = angle * .pi / 180.0
        let x = 0.5 + sin(radians) * 0.5
        let y = 0.5 - cos(radians) * 0.5
        return UnitPoint(x: x, y: y)
    }
}
