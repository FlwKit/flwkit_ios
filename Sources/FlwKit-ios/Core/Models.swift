import Foundation

// MARK: - Flow Models

// FlowPayloadV1 - matches backend response structure
public struct FlowPayloadV1: Codable {
    public let schemaVersion: Int
    public let flowKey: String
    public let version: Int
    public let entryScreenId: String
    public let defaultThemeId: String?
    public let themes: [Theme]
    public let screens: [Screen]
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case flowKey
        case version
        case entryScreenId
        case defaultThemeId
        case themes
        case screens
    }
}

// Flow - internal representation (converted from FlowPayloadV1)
public struct Flow: Codable {
    public let id: String
    public let key: String
    public let version: Int
    public let entryScreenId: String
    public let screens: [Screen]
    public let defaultThemeId: String?
    public let themes: [Theme]
    public let schemaVersion: Int
    
    // Computed property for compatibility
    public var flowKey: String {
        return key
    }
    
    public init(from payload: FlowPayloadV1) {
        self.id = payload.flowKey // Use flowKey as id
        self.key = payload.flowKey
        self.version = payload.version
        self.entryScreenId = payload.entryScreenId
        self.screens = payload.screens
        self.defaultThemeId = payload.defaultThemeId
        self.themes = payload.themes
        self.schemaVersion = payload.schemaVersion
    }
    
    // Legacy init for backwards compatibility
    public init(id: String, key: String, version: Int, screens: [Screen], defaultThemeId: String? = nil, schemaVersion: Int = 1, entryScreenId: String? = nil, themes: [Theme] = []) {
        self.id = id
        self.key = key
        self.version = version
        self.entryScreenId = entryScreenId ?? screens.first?.id ?? ""
        self.screens = screens
        self.defaultThemeId = defaultThemeId
        self.themes = themes
        self.schemaVersion = schemaVersion
    }
}

public struct Screen: Codable {
    public let id: String
    public let type: String
    public let themeId: String?
    public let blocks: [Block]
    
    public init(id: String, type: String = "standard", themeId: String? = nil, blocks: [Block]) {
        self.id = id
        self.type = type
        self.themeId = themeId
        self.blocks = blocks
    }
}

// MARK: - Block Models

public struct Block: Codable {
    public let type: String
    public let key: String?
    public let style: String?
    
    // Header block
    public let title: String?
    public let subtitle: String?
    
    // Media block
    public let imageUrl: String?
    public let videoUrl: String?
    
    // Choice block
    public let options: [ChoiceOption]?
    public let multiple: Bool?
    
    // Text input block
    public let placeholder: String?
    public let inputType: String?
    public let required: Bool?
    
    // Slider block
    public let min: Double?
    public let max: Double?
    public let step: Double?
    public let defaultValue: Double?
    
    // CTA block
    public let primary: CTAAction?
    public let secondary: CTAAction?
    
    // Spacer block
    public let size: String? // Token-based size: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
    public let height: Int? // Custom height in pixels (takes precedence over size)
    
    // Benefits list
    public let items: [String]?
    
    // Testimonial
    public let quote: String?
    public let author: String?
    
    // Footer
    public let text: String?
    
    enum CodingKeys: String, CodingKey {
        case type, key, style, title, subtitle
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case options, multiple, placeholder
        case inputType = "input_type"
        case required, min, max, step
        case defaultValue = "default_value"
        case primary, secondary, size, height, items, quote, author, text
    }
}

public struct ChoiceOption: Codable {
    public let label: String
    public let value: String
    public let icon: String?
    
    public init(label: String, value: String, icon: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
    }
}

public struct CTAAction: Codable {
    public let label: String
    public let action: String
    public let target: String?
    
    public init(label: String, action: String, target: String? = nil) {
        self.label = label
        self.action = action
        self.target = target
    }
}

// MARK: - Theme Models

public struct Theme: Codable {
    public let id: String
    public let tokens: ThemeTokens
    
    public init(id: String, tokens: ThemeTokens) {
        self.id = id
        self.tokens = tokens
    }
}

public struct ThemeTokens: Codable {
    public let background: String
    public let surface: String
    public let primary: String
    public let secondary: String?
    public let textPrimary: String
    public let textSecondary: String
    public let radius: String
    public let buttonStyle: String
    public let font: String
    
    enum CodingKeys: String, CodingKey {
        case background, surface, primary, secondary
        case textPrimary = "textPrimary"
        case textSecondary = "textSecondary"
        case radius
        case buttonStyle = "buttonStyle"
        case font
    }
    
    public init(background: String, surface: String, primary: String, secondary: String? = nil, textPrimary: String, textSecondary: String, radius: String, buttonStyle: String, font: String = "system") {
        self.background = background
        self.surface = surface
        self.primary = primary
        self.secondary = secondary
        self.textPrimary = textPrimary
        self.textSecondary = textSecondary
        self.radius = radius
        self.buttonStyle = buttonStyle
        self.font = font
    }
}

// MARK: - Flow State

public struct FlowState: Codable {
    public var currentScreenId: String?
    public var answers: [String: AnyCodable]
    public var attributes: [String: AnyCodable]
    public var flowKey: String
    public var userId: String?
    
    public init(flowKey: String, userId: String? = nil, currentScreenId: String? = nil, answers: [String: AnyCodable] = [:], attributes: [String: AnyCodable] = [:]) {
        self.flowKey = flowKey
        self.userId = userId
        self.currentScreenId = currentScreenId
        self.answers = answers
        self.attributes = attributes
    }
}

// MARK: - AnyCodable Helper

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}

