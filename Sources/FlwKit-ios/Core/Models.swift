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
    /// App ID (included by backend for Analytics v2; SDK uses it automatically)
    public let appId: String?
    /// Experiment context for the assigned session (if experiment is running)
    public let experiment: ExperimentContext?
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case flowKey
        case key
        case id
        case flowId
        case version
        case entryScreenId
        case defaultThemeId
        case theme
        case themes
        case screens
        case appId
        case experiment
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Screens are required for rendering; default to empty to avoid hard decode failures.
        let decodedScreens = try container.decodeIfPresent([Screen].self, forKey: .screens) ?? []
        self.screens = decodedScreens
        
        self.schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 1
        
        // Support multiple backend keys for flow identity.
        if let value = try container.decodeIfPresent(String.self, forKey: .flowKey) {
            self.flowKey = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .key) {
            self.flowKey = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .flowId) {
            self.flowKey = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .id) {
            self.flowKey = value
        } else {
            self.flowKey = "flow"
        }
        
        // Support both themes array and legacy single theme payload.
        if let decodedThemes = try container.decodeIfPresent([Theme].self, forKey: .themes) {
            self.themes = decodedThemes
        } else if let decodedTheme = try container.decodeIfPresent(Theme.self, forKey: .theme) {
            self.themes = [decodedTheme]
        } else {
            self.themes = []
        }
        
        self.defaultThemeId =
            (try container.decodeIfPresent(String.self, forKey: .defaultThemeId)) ??
            self.themes.first?.id
        
        self.entryScreenId =
            (try container.decodeIfPresent(String.self, forKey: .entryScreenId)) ??
            decodedScreens.first?.id ??
            ""
        
        self.appId = try container.decodeIfPresent(String.self, forKey: .appId)
        self.experiment = try container.decodeIfPresent(ExperimentContext.self, forKey: .experiment)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schemaVersion, forKey: .schemaVersion)
        try container.encode(flowKey, forKey: .flowKey)
        try container.encode(version, forKey: .version)
        try container.encode(entryScreenId, forKey: .entryScreenId)
        try container.encodeIfPresent(defaultThemeId, forKey: .defaultThemeId)
        try container.encode(themes, forKey: .themes)
        try container.encode(screens, forKey: .screens)
        try container.encodeIfPresent(appId, forKey: .appId)
        try container.encodeIfPresent(experiment, forKey: .experiment)
    }
}

public struct ExperimentContext: Codable {
    public let id: String
    public let variantId: String
    public let variantName: String
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
    /// App ID from backend (used automatically for Analytics v2)
    public let appId: String?
    public let experiment: ExperimentContext?
    
    // Computed property for compatibility
    public var flowKey: String {
        return key
    }
    
    public init(from payload: FlowPayloadV1) {
        self.id = payload.flowKey // Use flowKey as id
        self.key = payload.flowKey
        self.version = payload.version
        self.entryScreenId = payload.entryScreenId
        // Use screens in the order received from backend
        self.screens = payload.screens
        self.defaultThemeId = payload.defaultThemeId
        self.themes = payload.themes
        self.schemaVersion = payload.schemaVersion
        self.appId = payload.appId
        self.experiment = payload.experiment
    }
    
    // Legacy init for backwards compatibility
    public init(id: String, key: String, version: Int, screens: [Screen], defaultThemeId: String? = nil, schemaVersion: Int = 1, entryScreenId: String? = nil, themes: [Theme] = [], appId: String? = nil, experiment: ExperimentContext? = nil) {
        self.id = id
        self.key = key
        self.version = version
        self.entryScreenId = entryScreenId ?? screens.first?.id ?? ""
        self.screens = screens
        self.defaultThemeId = defaultThemeId
        self.themes = themes
        self.schemaVersion = schemaVersion
        self.appId = appId
        self.experiment = experiment
    }
}

public struct Screen: Codable {
    public let id: String
    public let type: String
    public let themeId: String?
    public let blocks: [Block]
    public let spacing: Double? // Vertical spacing between blocks in pixels (default: 16)
    
    // Background properties
    public let backgroundColor: String? // Hex color for solid background
    public let backgroundOpacity: Double? // 0-100 (percentage)
    public let backgroundType: String? // "solid" | "gradient"
    public let gradientStartColor: String? // Hex color for gradient start
    public let gradientStartOpacity: Double? // 0-100 (percentage)
    public let gradientEndColor: String? // Hex color for gradient end
    public let gradientEndOpacity: Double? // 0-100 (percentage)
    public let gradientAngle: Double? // 0-360 degrees
    
    enum CodingKeys: String, CodingKey {
        case id, type, themeId, blocks, spacing
        case _id
        case backgroundColor, backgroundOpacity, backgroundType
        case gradientStartColor, gradientStartOpacity
        case gradientEndColor, gradientEndOpacity, gradientAngle
    }
    
    public init(id: String, type: String = "standard", themeId: String? = nil, blocks: [Block], spacing: Double? = nil, backgroundColor: String? = nil, backgroundOpacity: Double? = nil, backgroundType: String? = nil, gradientStartColor: String? = nil, gradientStartOpacity: Double? = nil, gradientEndColor: String? = nil, gradientEndOpacity: Double? = nil, gradientAngle: Double? = nil) {
        self.id = id
        self.type = type
        self.themeId = themeId
        self.blocks = blocks
        self.spacing = spacing
        self.backgroundColor = backgroundColor
        self.backgroundOpacity = backgroundOpacity
        self.backgroundType = backgroundType
        self.gradientStartColor = gradientStartColor
        self.gradientStartOpacity = gradientStartOpacity
        self.gradientEndColor = gradientEndColor
        self.gradientEndOpacity = gradientEndOpacity
        self.gradientAngle = gradientAngle
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let value = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: ._id) {
            self.id = value
        } else {
            self.id = UUID().uuidString
        }
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? "standard"
        self.themeId = try container.decodeIfPresent(String.self, forKey: .themeId)
        self.blocks = try container.decodeIfPresent([Block].self, forKey: .blocks) ?? []
        self.spacing = try container.decodeIfPresent(Double.self, forKey: .spacing)
        
        self.backgroundColor = try container.decodeIfPresent(String.self, forKey: .backgroundColor)
        self.backgroundOpacity = try container.decodeIfPresent(Double.self, forKey: .backgroundOpacity)
        self.backgroundType = try container.decodeIfPresent(String.self, forKey: .backgroundType)
        self.gradientStartColor = try container.decodeIfPresent(String.self, forKey: .gradientStartColor)
        self.gradientStartOpacity = try container.decodeIfPresent(Double.self, forKey: .gradientStartOpacity)
        self.gradientEndColor = try container.decodeIfPresent(String.self, forKey: .gradientEndColor)
        self.gradientEndOpacity = try container.decodeIfPresent(Double.self, forKey: .gradientEndOpacity)
        self.gradientAngle = try container.decodeIfPresent(Double.self, forKey: .gradientAngle)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(themeId, forKey: .themeId)
        try container.encode(blocks, forKey: .blocks)
        try container.encodeIfPresent(spacing, forKey: .spacing)
        try container.encodeIfPresent(backgroundColor, forKey: .backgroundColor)
        try container.encodeIfPresent(backgroundOpacity, forKey: .backgroundOpacity)
        try container.encodeIfPresent(backgroundType, forKey: .backgroundType)
        try container.encodeIfPresent(gradientStartColor, forKey: .gradientStartColor)
        try container.encodeIfPresent(gradientStartOpacity, forKey: .gradientStartOpacity)
        try container.encodeIfPresent(gradientEndColor, forKey: .gradientEndColor)
        try container.encodeIfPresent(gradientEndOpacity, forKey: .gradientEndOpacity)
        try container.encodeIfPresent(gradientAngle, forKey: .gradientAngle)
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
    
    // Subtitle styling
    public let subtitleColor: String? // Hex (#RRGGBB) or rgba(r, g, b, a)
    public let subtitleOpacity: Double? // 0-100 (only used if subtitleColor is hex)
    public let subtitleFontSize: Double? // 8-200 pixels (default: 16)
    public let subtitleAlign: String? // 'left' | 'center' | 'right' (inherits from align if not set)
    public let subtitleSpacing: Double? // Letter spacing in pixels (default: 0)
    
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
    // Note: Typography, background, size, and border properties are shared with text input blocks (declared above)
    // Note: For choice blocks, height uses choiceHeight property
    public let choiceHeight: Double? // Height in pixels for choice options
    
    // Text input block
    public let placeholder: String?
    public let inputType: String?
    public let required: Bool?
    // Note: Typography properties (color, opacity, fontWeight, fontStyle, fontSize, align, spacing) are shared with header blocks (declared above)
    // Background properties
    public let backgroundColor: String? // Hex color (e.g., "#1f2937")
    public let backgroundOpacity: Double? // 0-100 (percentage)
    // Choice block specific - active state background
    public let activeBackgroundColor: String? // Hex color for selected state (e.g., "#10B981")
    public let activeBackgroundOpacity: Double? // 0-100 (percentage) for selected state
    // Size properties - width can be reused from MediaWidth (number or "auto"), height is separate for text inputs
    public let inputHeight: Double? // Height in pixels for text inputs (to avoid conflict with spacer height)
    // Border properties
    public let borderColor: String? // Hex color (e.g., "#6b7280")
    public let borderOpacity: Double? // 0-100 (percentage)
    public let borderWidth: Double? // Border width in pixels
    // Note: borderRadius is shared with media blocks (declared above)
    
    // Slider block
    public let min: Double?
    public let max: Double?
    public let step: Double?
    public let defaultValue: Double?
    
    // CTA block
    public let primary: CTAAction?
    public let secondary: CTAAction?
    public let sticky: Bool? // Default: true - sticky positioning at bottom
    // Note: Typography, background, size, and border properties are shared with text input blocks (declared above)
    // Note: For CTA blocks, height uses the same property as text inputs (inputHeight) or we can add ctaHeight
    public let ctaHeight: Double? // Height in pixels for CTA buttons
    
    // Spacer block
    public let size: String? // Token-based size: 'xs' | 'sm' | 'md' | 'lg' | 'xl'
    public let height: Double? // Custom height in pixels (takes precedence over size)
    
    // Benefits list
    public let items: [BenefitsListItem]?
    // Personalization block: timed sequence (items key holds [PersonalizationItem] when type == "personalization")
    public let personalizationItems: [PersonalizationItem]?
    // Note: Typography properties (color, opacity, fontWeight, fontStyle, fontSize, align, spacing) are shared with header blocks (declared above)
    // Icon properties for benefits list
    public let icon: String? // Lucide icon name (e.g., "Check", "Star", "Heart")
    public let iconColor: String? // Hex color (e.g., "#10B981")
    public let iconSize: Double? // Icon size in pixels (8-64, default: 16)
    
    // Testimonial
    public let quote: String?
    public let author: String?
    public let meta: String?
    
    // Footer
    public let text: String?
    
    // Progress bar
    public let fillColor: String? // Hex color for filled portion (e.g., "#3DDC97")
    public let fillOpacity: Double? // 0-100 (percentage) for filled portion

    // Permission blocks
    public let headline: String?
    public let permissionDescription: String?
    public let ctaLabel: String?
    public let skipLabel: String?
    public let onGranted: String?
    public let onDenied: String?

    // Processing animation block
    public let subHeadline: String?
    public let durationSeconds: Double?
    public let autoAdvance: Bool?
    public let processingItems: [String]?

    // Comparison table block
    public let leftLabel: String?
    public let rightLabel: String?
    public let rows: [ComparisonRow]?

    // Swipe cards block
    public let cards: [SwipeCard]?
    public let onComplete: String?
    
    enum CodingKeys: String, CodingKey {
        case type, key, style, title, subtitle
        case url
        case imageUrl = "image_url"
        case videoUrl = "video_url"
        case aspect, align, width
        case subtitleColor, subtitleOpacity, subtitleFontSize, subtitleAlign, subtitleSpacing
        case height // Used by both media and spacer blocks (as Double)
        case padding, margin
        case borderRadius = "borderRadius"
        case color, opacity
        case fontWeight = "fontWeight"
        case fontStyle = "fontStyle"
        case fontSize = "fontSize"
        case spacing
        case backgroundColor = "backgroundColor"
        case backgroundOpacity = "backgroundOpacity"
        case activeBackgroundColor = "activeBackgroundColor"
        case activeBackgroundOpacity = "activeBackgroundOpacity"
        case borderColor = "borderColor"
        case borderOpacity = "borderOpacity"
        case borderWidth = "borderWidth"
        // Note: height is already declared above and used for media, spacer, text_input, and cta blocks
        case options, multiple, placeholder
        case inputType = "input_type"
        case required, min, max, step
        case defaultValue = "default_value"
        case primary, secondary, sticky, size, items, quote, author, meta, text
        case fillColor = "fillColor"
        case fillOpacity = "fillOpacity"
        case icon
        case iconColor = "iconColor"
        case iconColorSnake = "icon_color" // Support both formats
        case iconSize = "iconSize"
        case iconSizeSnake = "icon_size" // Support both formats
        case headline
        case permissionDescription = "description"
        case ctaLabel
        case skipLabel
        case onGranted
        case onDenied
        case subHeadline
        case durationSeconds
        case autoAdvance
        case leftLabel
        case rightLabel
        case rows
        case cards
        case onComplete
    }
    
    // Custom decoding to handle "height" for both media and spacer blocks
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? "unknown"
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
        
        // Subtitle styling properties
        subtitleColor = try container.decodeIfPresent(String.self, forKey: .subtitleColor)
        subtitleOpacity = try container.decodeIfPresent(Double.self, forKey: .subtitleOpacity)
        subtitleFontSize = try container.decodeIfPresent(Double.self, forKey: .subtitleFontSize)
        subtitleAlign = try container.decodeIfPresent(String.self, forKey: .subtitleAlign)
        subtitleSpacing = try container.decodeIfPresent(Double.self, forKey: .subtitleSpacing)
        
        // Try to decode URL - check multiple possible field names
        url = try container.decodeIfPresent(String.self, forKey: .url)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        aspect = try container.decodeIfPresent(String.self, forKey: .aspect)
        // Note: align is already decoded above (shared between header and media blocks)
        width = try container.decodeIfPresent(MediaWidth.self, forKey: .width)
        padding = try container.decodeIfPresent(MediaPadding.self, forKey: .padding)
        margin = try container.decodeIfPresent(MediaMargin.self, forKey: .margin)
        borderRadius = try container.decodeIfPresent(Double.self, forKey: .borderRadius)
        if let decodedOptions = try? container.decode(LossyArray<ChoiceOption>.self, forKey: .options) {
            options = decodedOptions.elements
        } else {
            options = nil
        }
        multiple = try? container.decodeIfPresent(Bool.self, forKey: .multiple)
        placeholder = try? container.decodeIfPresent(String.self, forKey: .placeholder)
        inputType = try? container.decodeIfPresent(String.self, forKey: .inputType)
        required = try? container.decodeIfPresent(Bool.self, forKey: .required)
        
        // Text input and choice styling properties
        backgroundColor = try? container.decodeIfPresent(String.self, forKey: .backgroundColor)
        backgroundOpacity = try? container.decodeIfPresent(Double.self, forKey: .backgroundOpacity)
        activeBackgroundColor = try? container.decodeIfPresent(String.self, forKey: .activeBackgroundColor)
        activeBackgroundOpacity = try? container.decodeIfPresent(Double.self, forKey: .activeBackgroundOpacity)
        borderColor = try? container.decodeIfPresent(String.self, forKey: .borderColor)
        borderOpacity = try? container.decodeIfPresent(Double.self, forKey: .borderOpacity)
        borderWidth = try? container.decodeIfPresent(Double.self, forKey: .borderWidth)
        min = try? container.decodeIfPresent(Double.self, forKey: .min)
        max = try? container.decodeIfPresent(Double.self, forKey: .max)
        step = try? container.decodeIfPresent(Double.self, forKey: .step)
        defaultValue = try? container.decodeIfPresent(Double.self, forKey: .defaultValue)
        primary = try? container.decodeIfPresent(CTAAction.self, forKey: .primary)
        secondary = try? container.decodeIfPresent(CTAAction.self, forKey: .secondary)
        sticky = try? container.decodeIfPresent(Bool.self, forKey: .sticky)
        size = try? container.decodeIfPresent(String.self, forKey: .size)
        if type == "personalization" {
            if let decoded = try? container.decode(LossyArray<PersonalizationItem>.self, forKey: .items) {
                personalizationItems = decoded.elements
            } else {
                personalizationItems = nil
            }
            processingItems = nil
            items = nil
        } else if type == "processing_animation" {
            processingItems = try? container.decodeIfPresent([String].self, forKey: .items)
            personalizationItems = nil
            items = nil
        } else {
            processingItems = nil
            personalizationItems = nil
            if let decoded = try? container.decode(LossyArray<BenefitsListItem>.self, forKey: .items) {
                items = decoded.elements
            } else {
                items = nil
            }
        }

        // Decode icon properties with maximum flexibility - handle all possible formats and types
        // Use try? to gracefully handle any decoding errors
        icon = try? container.decodeIfPresent(String.self, forKey: .icon)
        
        // Try to decode iconColor - support both camelCase and snake_case
        if let iconColorCamel = try? container.decodeIfPresent(String.self, forKey: .iconColor) {
            iconColor = iconColorCamel
        } else if let iconColorSnake = try? container.decodeIfPresent(String.self, forKey: .iconColorSnake) {
            iconColor = iconColorSnake
        } else {
            iconColor = nil
        }
        
        // Try to decode iconSize - support both camelCase and snake_case, and handle String conversion
        let decodedIconSize: Double? = {
            if let iconSizeValue = try? container.decodeIfPresent(Double.self, forKey: .iconSize) {
                return iconSizeValue
            } else if let iconSizeSnake = try? container.decodeIfPresent(Double.self, forKey: .iconSizeSnake) {
                return iconSizeSnake
            } else if let iconSizeString = try? container.decodeIfPresent(String.self, forKey: .iconSize),
                      let iconSizeDouble = Double(iconSizeString) {
                return iconSizeDouble
            } else if let iconSizeStringSnake = try? container.decodeIfPresent(String.self, forKey: .iconSizeSnake),
                      let iconSizeDouble = Double(iconSizeStringSnake) {
                return iconSizeDouble
            }
            return nil
        }()
        iconSize = decodedIconSize
        
        quote = try? container.decodeIfPresent(String.self, forKey: .quote)
        author = try? container.decodeIfPresent(String.self, forKey: .author)
        meta = try? container.decodeIfPresent(String.self, forKey: .meta)
        text = try? container.decodeIfPresent(String.self, forKey: .text)
        fillColor = try? container.decodeIfPresent(String.self, forKey: .fillColor)
        fillOpacity = try? container.decodeIfPresent(Double.self, forKey: .fillOpacity)
        headline = try? container.decodeIfPresent(String.self, forKey: .headline)
        permissionDescription = try? container.decodeIfPresent(String.self, forKey: .permissionDescription)
        ctaLabel = try? container.decodeIfPresent(String.self, forKey: .ctaLabel)
        skipLabel = try? container.decodeIfPresent(String.self, forKey: .skipLabel)
        onGranted = try? container.decodeIfPresent(String.self, forKey: .onGranted)
        onDenied = try? container.decodeIfPresent(String.self, forKey: .onDenied)
        subHeadline = try? container.decodeIfPresent(String.self, forKey: .subHeadline)
        durationSeconds = try? container.decodeIfPresent(Double.self, forKey: .durationSeconds)
        autoAdvance = try? container.decodeIfPresent(Bool.self, forKey: .autoAdvance)
        leftLabel = try? container.decodeIfPresent(String.self, forKey: .leftLabel)
        rightLabel = try? container.decodeIfPresent(String.self, forKey: .rightLabel)
        if let decodedRows = try? container.decode(LossyArray<ComparisonRow>.self, forKey: .rows) {
            rows = decodedRows.elements
        } else {
            rows = nil
        }
        if let decodedCards = try? container.decode(LossyArray<SwipeCard>.self, forKey: .cards) {
            cards = decodedCards.elements
        } else {
            cards = nil
        }
        onComplete = try? container.decodeIfPresent(String.self, forKey: .onComplete)
        
        // Handle "height" - media, spacer, text_input, cta, and choice blocks use it as Double
        let heightValue = try container.decodeIfPresent(Double.self, forKey: .height)
        if type == "media" {
            mediaHeight = heightValue
            height = nil
            inputHeight = nil
            ctaHeight = nil
            choiceHeight = nil
        } else if type == "text_input" {
            inputHeight = heightValue
            mediaHeight = nil
            height = nil
            ctaHeight = nil
            choiceHeight = nil
        } else if type == "cta" {
            ctaHeight = heightValue
            mediaHeight = nil
            inputHeight = nil
            height = nil
            choiceHeight = nil
        } else if type == "choice" {
            choiceHeight = heightValue
            mediaHeight = nil
            inputHeight = nil
            ctaHeight = nil
            height = nil
        } else {
            // For spacer and other blocks
            mediaHeight = nil
            inputHeight = nil
            ctaHeight = nil
            choiceHeight = nil
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
        try container.encodeIfPresent(subtitleColor, forKey: .subtitleColor)
        try container.encodeIfPresent(subtitleOpacity, forKey: .subtitleOpacity)
        try container.encodeIfPresent(subtitleFontSize, forKey: .subtitleFontSize)
        try container.encodeIfPresent(subtitleAlign, forKey: .subtitleAlign)
        try container.encodeIfPresent(subtitleSpacing, forKey: .subtitleSpacing)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(videoUrl, forKey: .videoUrl)
        try container.encodeIfPresent(aspect, forKey: .aspect)
        try container.encodeIfPresent(width, forKey: .width)
        try container.encodeIfPresent(padding, forKey: .padding)
        try container.encodeIfPresent(margin, forKey: .margin)
        try container.encodeIfPresent(borderRadius, forKey: .borderRadius)
        try container.encodeIfPresent(options, forKey: .options)
        try container.encodeIfPresent(multiple, forKey: .multiple)
        try container.encodeIfPresent(placeholder, forKey: .placeholder)
        try container.encodeIfPresent(inputType, forKey: .inputType)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(backgroundColor, forKey: .backgroundColor)
        try container.encodeIfPresent(backgroundOpacity, forKey: .backgroundOpacity)
        try container.encodeIfPresent(activeBackgroundColor, forKey: .activeBackgroundColor)
        try container.encodeIfPresent(activeBackgroundOpacity, forKey: .activeBackgroundOpacity)
        try container.encodeIfPresent(borderColor, forKey: .borderColor)
        try container.encodeIfPresent(borderOpacity, forKey: .borderOpacity)
        try container.encodeIfPresent(borderWidth, forKey: .borderWidth)
        try container.encodeIfPresent(min, forKey: .min)
        try container.encodeIfPresent(max, forKey: .max)
        try container.encodeIfPresent(step, forKey: .step)
        try container.encodeIfPresent(defaultValue, forKey: .defaultValue)
        try container.encodeIfPresent(primary, forKey: .primary)
        try container.encodeIfPresent(secondary, forKey: .secondary)
        try container.encodeIfPresent(sticky, forKey: .sticky)
        try container.encodeIfPresent(size, forKey: .size)
        if type == "personalization" {
            try container.encodeIfPresent(personalizationItems, forKey: .items)
        } else if type == "processing_animation" {
            try container.encodeIfPresent(processingItems, forKey: .items)
        } else {
            try container.encodeIfPresent(items, forKey: .items)
        }
        try container.encodeIfPresent(icon, forKey: .icon)
        try container.encodeIfPresent(iconColor, forKey: .iconColor)
        try container.encodeIfPresent(iconSize, forKey: .iconSize)
        try container.encodeIfPresent(quote, forKey: .quote)
        try container.encodeIfPresent(author, forKey: .author)
        try container.encodeIfPresent(meta, forKey: .meta)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encodeIfPresent(fillColor, forKey: .fillColor)
        try container.encodeIfPresent(fillOpacity, forKey: .fillOpacity)
        try container.encodeIfPresent(headline, forKey: .headline)
        try container.encodeIfPresent(permissionDescription, forKey: .permissionDescription)
        try container.encodeIfPresent(ctaLabel, forKey: .ctaLabel)
        try container.encodeIfPresent(skipLabel, forKey: .skipLabel)
        try container.encodeIfPresent(onGranted, forKey: .onGranted)
        try container.encodeIfPresent(onDenied, forKey: .onDenied)
        try container.encodeIfPresent(subHeadline, forKey: .subHeadline)
        try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
        try container.encodeIfPresent(autoAdvance, forKey: .autoAdvance)
        try container.encodeIfPresent(leftLabel, forKey: .leftLabel)
        try container.encodeIfPresent(rightLabel, forKey: .rightLabel)
        try container.encodeIfPresent(rows, forKey: .rows)
        try container.encodeIfPresent(cards, forKey: .cards)
        try container.encodeIfPresent(onComplete, forKey: .onComplete)
        
        // Encode height based on block type
        if type == "media" {
            try container.encodeIfPresent(mediaHeight, forKey: .height)
        } else if type == "text_input" {
            try container.encodeIfPresent(inputHeight, forKey: .height)
        } else if type == "cta" {
            try container.encodeIfPresent(ctaHeight, forKey: .height)
        } else if type == "choice" {
            try container.encodeIfPresent(choiceHeight, forKey: .height)
        } else {
            try container.encodeIfPresent(height, forKey: .height)
        }
    }
}

private struct LossyArray<Element: Decodable>: Decodable {
    let elements: [Element]
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var decoded: [Element] = []
        
        while !container.isAtEnd {
            if let item = try? container.decode(Element.self) {
                decoded.append(item)
            } else {
                _ = try? container.decode(AnyCodable.self)
            }
        }
        
        elements = decoded
    }
}

// MARK: - Media Block Supporting Types

// MediaWidth can be a number or "auto" string
public enum MediaWidth: Codable {
    case auto
    case fixed(Double)
    case percentage(String) // For percentage strings like "100%", "50%"
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            if string == "auto" {
                self = .auto
            } else if string.hasSuffix("%") {
                // Percentage string like "100%", "50%"
                self = .percentage(string)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid width string: \(string)")
            }
        } else if let number = try? container.decode(Double.self) {
            self = .fixed(number)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Width must be a number, 'auto' string, or percentage string")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .auto:
            try container.encode("auto")
        case .fixed(let value):
            try container.encode(value)
        case .percentage(let value):
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
    public let icon: String? // Legacy support for icon/emoji
    public let emoji: String? // New: emoji support
    public let action: String? // Per-option action: 'next' | 'back' | 'skip' | 'close' | 'submit'
    
    public init(label: String, value: String, icon: String? = nil, emoji: String? = nil, action: String? = nil) {
        self.label = label
        self.value = value
        self.icon = icon
        self.emoji = emoji
        self.action = action
    }
}

public struct BenefitsListItem: Codable {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

// Personalization block: timed sequence of texts; backend validates durationMs 500–60_000
public struct PersonalizationItem: Codable {
    public let text: String
    public let durationMs: Double

    enum CodingKeys: String, CodingKey {
        case text
        case durationMs
        case durationMsSnake = "duration_ms"
    }

    public init(text: String, durationMs: Double) {
        self.text = text
        self.durationMs = durationMs
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decode(String.self, forKey: .text)
        let ms: Double
        if let intVal = try? container.decode(Int.self, forKey: .durationMs) {
            ms = Double(intVal)
        } else if let doubleVal = try? container.decode(Double.self, forKey: .durationMs) {
            ms = doubleVal
        } else if let intVal = try? container.decode(Int.self, forKey: .durationMsSnake) {
            ms = Double(intVal)
        } else {
            ms = try container.decode(Double.self, forKey: .durationMsSnake)
        }
        durationMs = ms
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(text, forKey: .text)
        try container.encode(durationMs, forKey: .durationMs)
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

public struct ComparisonRow: Codable {
    public let feature: String
    public let leftValue: String
    public let rightValue: String
    public let highlighted: Bool?
}

public struct SwipeCard: Codable {
    public let id: String
    public let text: String
    public let emoji: String?
}

// MARK: - Theme Models

public struct Theme: Codable {
    public let id: String
    public let tokens: ThemeTokens
    
    // Background properties
    public let backgroundType: String? // "solid" | "gradient"
    public let gradientStartColor: String? // Hex color for gradient start
    public let gradientStartOpacity: Double? // 0-100 (percentage)
    public let gradientEndColor: String? // Hex color for gradient end
    public let gradientEndOpacity: Double? // 0-100 (percentage)
    public let gradientAngle: Double? // 0-360 degrees
    
    enum CodingKeys: String, CodingKey {
        case id, tokens
        case _id
        case backgroundType
        case gradientStartColor, gradientStartOpacity
        case gradientEndColor, gradientEndOpacity, gradientAngle
    }
    
    public init(id: String, tokens: ThemeTokens, backgroundType: String? = nil, gradientStartColor: String? = nil, gradientStartOpacity: Double? = nil, gradientEndColor: String? = nil, gradientEndOpacity: Double? = nil, gradientAngle: Double? = nil) {
        self.id = id
        self.tokens = tokens
        self.backgroundType = backgroundType
        self.gradientStartColor = gradientStartColor
        self.gradientStartOpacity = gradientStartOpacity
        self.gradientEndColor = gradientEndColor
        self.gradientEndOpacity = gradientEndOpacity
        self.gradientAngle = gradientAngle
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let value = try container.decodeIfPresent(String.self, forKey: .id) {
            self.id = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: ._id) {
            self.id = value
        } else {
            self.id = "theme_default"
        }
        self.tokens = try container.decodeIfPresent(ThemeTokens.self, forKey: .tokens)
            ?? ThemeTokens(
                background: "#FFFFFF",
                surface: "#F3F4F6",
                primary: "#6EBA81",
                textPrimary: "#111827",
                textSecondary: "#6B7280",
                radius: "md",
                buttonStyle: "filled",
                font: "system"
            )
        self.backgroundType = try container.decodeIfPresent(String.self, forKey: .backgroundType)
        self.gradientStartColor = try container.decodeIfPresent(String.self, forKey: .gradientStartColor)
        self.gradientStartOpacity = try container.decodeIfPresent(Double.self, forKey: .gradientStartOpacity)
        self.gradientEndColor = try container.decodeIfPresent(String.self, forKey: .gradientEndColor)
        self.gradientEndOpacity = try container.decodeIfPresent(Double.self, forKey: .gradientEndOpacity)
        self.gradientAngle = try container.decodeIfPresent(Double.self, forKey: .gradientAngle)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(tokens, forKey: .tokens)
        try container.encodeIfPresent(backgroundType, forKey: .backgroundType)
        try container.encodeIfPresent(gradientStartColor, forKey: .gradientStartColor)
        try container.encodeIfPresent(gradientStartOpacity, forKey: .gradientStartOpacity)
        try container.encodeIfPresent(gradientEndColor, forKey: .gradientEndColor)
        try container.encodeIfPresent(gradientEndOpacity, forKey: .gradientEndOpacity)
        try container.encodeIfPresent(gradientAngle, forKey: .gradientAngle)
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
        case textPrimarySnake = "text_primary"
        case textSecondary = "textSecondary"
        case textSecondarySnake = "text_secondary"
        case radius
        case buttonStyle = "buttonStyle"
        case buttonStyleSnake = "button_style"
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
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.background = try container.decodeIfPresent(String.self, forKey: .background) ?? "#FFFFFF"
        self.surface = try container.decodeIfPresent(String.self, forKey: .surface) ?? "#F3F4F6"
        self.primary = try container.decodeIfPresent(String.self, forKey: .primary) ?? "#6EBA81"
        self.secondary = try container.decodeIfPresent(String.self, forKey: .secondary)
        if let value = try container.decodeIfPresent(String.self, forKey: .textPrimary) {
            self.textPrimary = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .textPrimarySnake) {
            self.textPrimary = value
        } else {
            self.textPrimary = "#111827"
        }
        if let value = try container.decodeIfPresent(String.self, forKey: .textSecondary) {
            self.textSecondary = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .textSecondarySnake) {
            self.textSecondary = value
        } else {
            self.textSecondary = "#6B7280"
        }
        self.radius = try container.decodeIfPresent(String.self, forKey: .radius) ?? "md"
        if let value = try container.decodeIfPresent(String.self, forKey: .buttonStyle) {
            self.buttonStyle = value
        } else if let value = try container.decodeIfPresent(String.self, forKey: .buttonStyleSnake) {
            self.buttonStyle = value
        } else {
            self.buttonStyle = "filled"
        }
        self.font = try container.decodeIfPresent(String.self, forKey: .font) ?? "system"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(background, forKey: .background)
        try container.encode(surface, forKey: .surface)
        try container.encode(primary, forKey: .primary)
        try container.encodeIfPresent(secondary, forKey: .secondary)
        try container.encode(textPrimary, forKey: .textPrimary)
        try container.encode(textSecondary, forKey: .textSecondary)
        try container.encode(radius, forKey: .radius)
        try container.encode(buttonStyle, forKey: .buttonStyle)
        try container.encode(font, forKey: .font)
    }
}

// MARK: - Flow State

public struct FlowState: Codable {
    public var currentScreenId: String?
    public var answers: [String: AnyCodable]
    public var attributes: [String: AnyCodable]
    public var flowKey: String
    public var userId: String?
    public var totalScreens: Int? // Total number of screens in the flow (for progress calculation)
    public var currentScreenIndex: Int? // Current screen index (0-based) for progress calculation
    
    public init(flowKey: String, userId: String? = nil, currentScreenId: String? = nil, answers: [String: AnyCodable] = [:], attributes: [String: AnyCodable] = [:], totalScreens: Int? = nil, currentScreenIndex: Int? = nil) {
        self.flowKey = flowKey
        self.userId = userId
        self.currentScreenId = currentScreenId
        self.answers = answers
        self.attributes = attributes
        self.totalScreens = totalScreens
        self.currentScreenIndex = currentScreenIndex
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

// MARK: - A/B Testing Models

/// A/B test variant response from backend
public struct ABTestResponse: Codable {
    public let hasActiveTest: Bool
    public let experimentId: String? // Changed from testId
    public let testName: String?
    public let variant: Variant?
    public let flowVersionId: String?
    public let flowData: FlowPayloadV1? // NEW: Complete flow data with resolved assets
    
    enum CodingKeys: String, CodingKey {
        case hasActiveTest
        case experimentId
        case testName
        case variant
        case flowVersionId
        case flowData
    }
}

/// A/B test variant information
public struct Variant: Codable {
    public let id: String
    public let name: String
    public let flowVersionId: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case flowVersionId
    }
}

/// Cached A/B test variant assignment
struct CachedVariant {
    let flowKey: String
    let variant: ABTestResponse
    let expiresAt: Date
    let userId: String?
    let sessionId: String
    
    var isExpired: Bool {
        return Date() > expiresAt
    }
}
