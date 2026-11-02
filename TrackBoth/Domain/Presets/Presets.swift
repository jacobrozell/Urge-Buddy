import Foundation

struct Preset: Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var iconName: String
    /// Verb phrase for "When did you last …?" Vices only.
    var lastUseVerb: String
    /// Default unit when counted (cut back, amount habits).
    var unit: String = ""
    /// Habits only. A preset that starts as an amount habit.
    var dailyTarget: Int? = nil
}

enum Presets {
    static let customVerb = "do it"
    static let fallbackIcon = "circle.dashed"

    static let vices: [Preset] = [
        Preset(id: "alcohol", name: "Alcohol", iconName: "wineglass", lastUseVerb: "drink", unit: "drinks"),
        Preset(id: "smoking", name: "Smoking", iconName: "smoke", lastUseVerb: "smoke", unit: "cigarettes"),
        Preset(id: "vaping", name: "Vaping", iconName: "cloud", lastUseVerb: "vape", unit: "sessions"),
        Preset(id: "cannabis", name: "Cannabis", iconName: "leaf", lastUseVerb: "use cannabis", unit: "sessions"),
        Preset(id: "gambling", name: "Gambling", iconName: "dice", lastUseVerb: "gamble", unit: "bets"),
        Preset(id: "porn", name: "Porn", iconName: "eye.slash", lastUseVerb: "watch porn", unit: "times"),
        Preset(id: "social-media", name: "Social media", iconName: "iphone", lastUseVerb: "scroll social media", unit: "minutes"),
        Preset(id: "gaming", name: "Gaming", iconName: "gamecontroller", lastUseVerb: "game", unit: "hours"),
        Preset(id: "junk-food", name: "Junk food", iconName: "takeoutbag.and.cup.and.straw", lastUseVerb: "eat junk food", unit: "snacks"),
        Preset(id: "shopping", name: "Impulse shopping", iconName: "bag", lastUseVerb: "impulse shop", unit: "purchases"),
        Preset(id: "caffeine", name: "Caffeine", iconName: "cup.and.saucer", lastUseVerb: "have caffeine", unit: "cups")
    ]

    static let habits: [Preset] = [
        Preset(id: "walk", name: "Go for a walk", iconName: "figure.walk", lastUseVerb: ""),
        Preset(id: "exercise", name: "Exercise", iconName: "figure.run", lastUseVerb: ""),
        Preset(id: "water", name: "Drink water", iconName: "drop", lastUseVerb: "", unit: "glasses", dailyTarget: 8),
        Preset(id: "reach-out", name: "Call or text a friend", iconName: "phone", lastUseVerb: ""),
        Preset(id: "breathe", name: "Breathe / meditate", iconName: "wind", lastUseVerb: ""),
        Preset(id: "journal", name: "Journal", iconName: "book.closed", lastUseVerb: ""),
        Preset(id: "outside", name: "Time outside", iconName: "sun.max", lastUseVerb: ""),
        Preset(id: "meal", name: "Eat a real meal", iconName: "fork.knife", lastUseVerb: ""),
        Preset(id: "sleep", name: "In bed by 11", iconName: "bed.double", lastUseVerb: ""),
        Preset(id: "meeting", name: "Support group / meeting", iconName: "person.3", lastUseVerb: "")
    ]

    /// Icons offered in addition to the preset symbols.
    static let extraIconNames: [String] = [
        "heart", "star", "moon.stars", "book", "figure.mind.and.body", "lungs",
        "pills", "creditcard", "tv", "car", "house", "brain"
    ]

    static var symbolNames: [String] {
        let presetIcons = (vices + habits).map(\.iconName)
        let triggerIcons = TriggerTag.allCases.map(\.systemImage)
        return Array(Set(presetIcons + extraIconNames + triggerIcons + [fallbackIcon])).sorted()
    }

    static func iconName(matching name: String) -> String {
        let key = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return (vices + habits).first { $0.name.lowercased() == key }?.iconName ?? fallbackIcon
    }
}
