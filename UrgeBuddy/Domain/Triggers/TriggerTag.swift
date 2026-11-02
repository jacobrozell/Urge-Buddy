import Foundation

enum TriggerTag: String, CaseIterable, Codable, Identifiable {
    case hungry, angry, lonely, tired
    case stressed, anxious, sad, bored
    case celebrating, social, cue, routine, other
    var id: String { rawValue }

    var title: String {
        switch self {
        case .hungry: "Hungry"
        case .angry: "Angry"
        case .lonely: "Lonely"
        case .tired: "Tired"
        case .stressed: "Stressed"
        case .anxious: "Anxious"
        case .sad: "Down"
        case .bored: "Bored"
        case .celebrating: "Celebrating"
        case .social: "Around others"
        case .cue: "Saw it nearby"
        case .routine: "Usual time"
        case .other: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .hungry: "fork.knife"
        case .angry: "flame"
        case .lonely: "person"
        case .tired: "bed.double"
        case .stressed: "bolt.heart"
        case .anxious: "waveform.path.ecg"
        case .sad: "cloud.rain"
        case .bored: "hourglass"
        case .celebrating: "party.popper"
        case .social: "person.3"
        case .cue: "eye"
        case .routine: "clock"
        case .other: "ellipsis.circle"
        }
    }

    static func encode(_ tags: [TriggerTag]) -> String { tags.map(\.rawValue).joined(separator: "|") }
    static func decode(_ raw: String) -> [TriggerTag] { raw.split(separator: "|").compactMap { TriggerTag(rawValue: String($0)) } }
}
