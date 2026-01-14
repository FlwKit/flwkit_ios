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
    public let spacing: Double? // Vertical spacing between blocks in pixels (default: 16)
    
    public init(id: String, type: String = "standard", themeId: String? = nil, blocks: [Block], spacing: Double? = nil) {
        self.id = id
        self.type = type
        self.themeId = themeId
        self.blocks = blocks
        self.spacing = spacing
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
    public let align: String? // 'left' | 'center' | 'right' (default: 'left')
    public let color: String? // Hex color (e.g., "#ffffff") - uses theme's textPrimary if undefined
    public let opacity: Double? // Opacity percentage 0-100 (default: 100)
    public let fontWeight: String? // 'normal' | 'bold' (default: 'bold')
    public let fontStyle: String? // 'normal' | 'italic' (default: 'normal')
    public let fontSize: Double? // Font size in pixels (default: 24)
    public let spacing: Double? // Letter spacing in pixels (default: undefined)
    
    // Media block
    public let url: String? // Resolved URL from backend (replaces imageUrl)
    public let imageUrl: String? // Legacy support
    public let videoUrl: String?
    public let aspect: String? // 'square' | 'wide' | 'tall'
    // Note: align is shared between header and media blocks (declared above)
    public let width: MediaWidth? // number or "auto" string
    public let mediaHeight: Double? // Height in pixels (renamed to avoid conflict with spacer height)
    public let padding: MediaPadding?
    public let margin: MediaMargin?
    public let borderRadius: Double?
    
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
    public let height: Double? // Custom height in pixels (takes precedence over size)
    
    // Benefits list
    public let items: [String]?
    
    // Testimonial
    public let quote: String?
    public let author: String?
    
    // Footer
    public let text: String?
    
    enum CodingKeys: String, CodingKey {
        case type, key, style, title, subtitle
        case url
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case aspect, align, width
        case height // Used by both media and spacer blocks (as Double)
        case padding, margin
        case borderRadius = "borderRadius"
        case color, opacity
        case fontWeight = "fontWeight"
        case fontStyle = "fontStyle"
        case fontSize = "fontSize"
        case spacing
        case options, multiple, placeholder
        case inputType = "input_type"
        case required, min, max, step
        case defaultValue = "default_value"
        case primary, secondary, size, items, quote, author, text
    }
    
    // Custom decoding to handle "height" for both media and spacer blocks
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decode(String.self, forKey: .type)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        style = try container.decodeIfPresent(String.self, forKey: .style)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        
        // Header typography properties
        align = try container.decodeIfPresent(String.self, forKey: .align)
        color = try container.decodeIfPresent(String.self, forKey: .color)
        opacity = try container.decodeIfPresent(Double.self, forKey: .opacity)
        fontWeight = try container.decodeIfPresent(String.self, forKey: .fontWeight)
        fontStyle = try container.decodeIfPresent(String.self, forKey: .fontStyle)
        fontSize = try container.decodeIfPresent(Double.self, forKey: .fontSize)
        spacing = try container.decodeIfPresent(Double.self, forKey: .spacing)
        
        // Try to decode URL - check multiple possible field names
        url = try container.decodeIfPresent(String.self, forKey: .url)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        aspect = try container.decodeIfPresent(String.self, forKey: .aspect)
        align = try container.decodeIfPresent(String.self, forKey: .align)
        width = try container.decodeIfPresent(MediaWidth.self, forKey: .width)
        padding = try container.decodeIfPresent(MediaPadding.self, forKey: .padding)
        margin = try container.decodeIfPresent(MediaMargin.self, forKey: .margin)
        borderRadius = try container.decodeIfPresent(Double.self, forKey: .borderRadius)
        options = try container.decodeIfPresent([ChoiceOption].self, forKey: .options)
        multiple = try container.decodeIfPresent(Bool.self, forKey: .multiple)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        inputType = try container.decodeIfPresent(String.self, forKey: .inputType)
        required = try container.decodeIfPresent(Bool.self, forKey: .required)
        min = try container.decodeIfPresent(Double.self, forKey: .min)
        max = try container.decodeIfPresent(Double.self, forKey: .max)
        step = try container.decodeIfPresent(Double.self, forKey: .step)
        defaultValue = try container.decodeIfPresent(Double.self, forKey: .defaultValue)
        primary = try container.decodeIfPresent(CTAAction.self, forKey: .primary)
        secondary = try container.decodeIfPresent(CTAAction.self, forKey: .secondary)
        size = try container.decodeIfPresent(String.self, forKey: .size)
        items = try container.decodeIfPresent([String].self, forKey: .items)
        quote = try container.decodeIfPresent(String.self, forKey: .quote)
        author = try container.decodeIfPresent(String.self, forKey: .author)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        
        // Handle "height" - both media and spacer blocks use it as Double
        let heightValue = try container.decodeIfPresent(Double.self, forKey: .height)
        if type == "media" {
            mediaHeight = heightValue
            height = nil // Not used for media blocks
        } else {
            // For spacer and other blocks
            mediaHeight = nil
            height = heightValue
        }
    }
    
    // Custom encoding
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(key, forKey: .key)
        try container.encodeIfPresent(style, forKey: .style)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(align, forKey: .align)
        try container.encodeIfPresent(color, forKey: .color)
        try container.encodeIfPresent(opacity, forKey: .opacity)
        try container.encodeIfPresent(fontWeight, forKey: .fontWeight)
        try container.encodeIfPresent(fontStyle, forKey: .fontStyle)
        try container.encodeIfPresent(fontSize, forKey: .fontSize)
        try container.encodeIfPresent(spacing, forKey: .spacing)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrl)
        try container.encodeIfPresent(aspect, forKey: .aspect)
        try container.encodeIfPresent(align, forKey: .align)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(padding, forKey: .padding)
        try container.encodeIfPresent(margin, forKey: .margin)
        try container.encodeIfPresent(borderRadius, forKey: .borderRadius)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(multiple, forKey: .multiple)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
        try container.encodeIfPresent(inputType, forKey: .inputType)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(min, forKey: .min)
        try container.encodeIfPresent(max, forKey: .max)
        try container.encodeIfPresent(step, forKey: .step)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(primary, forKey: .primary)
        try container.encodeIfPresent(secondary, forKey: .secondary)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(quote, forKey: .quote)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(text, forKey: .text)
        
        // Encode height based on block type
        if type == "media" {
            try container.encodeIfPresent(mediaHeight, forKey: .height)
        } else {
            try container.encodeIfPresent(height, forKey: .height)
        }
    }
}

// MARK: - Media Block Supporting Types

// MediaWidth can be a number or "auto" string
public enum MediaWidth: Codable {
    case auto
    case fixed(Double)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if string == "auto" {
                self = .auto
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid width string: \(string)")
            }
        } else if let number = try? container.decode(Double.self) {
            self = .fixed(number)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Width must be a number or 'auto' string")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auto:
            try container.encode("auto")
        case .fixed(let value):
            try container.encode(value)
        }
    }
}

public struct MediaPadding: Codable {
    public let vertical: Double?
    public let horizontal: Double?
    
    public init(vertical: Double? = nil, horizontal: Double? = nil) {
        self.vertical = vertical
        self.horizontal = horizontal
    }
}

public struct MediaMargin: Codable {
    public let top: Double?
    public let bottom: Double?
    public let left: Double?
    public let right: Double?
    
    public init(top: Double? = nil, bottom: Double? = nil, left: Double? = nil, right: Double? = nil) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
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

