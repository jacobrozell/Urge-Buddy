import Foundation

enum MilestoneLedger {
    private static let key = "milestoneLedger.v2"

    static func highestCelebrated(for id: UUID) -> Int {
        load()[id.uuidString] ?? 0
    }

    static func record(_ threshold: Int, for id: UUID) {
        var map = load()
        map[id.uuidString] = threshold
        save(map)
    }

    static func reset(for id: UUID) {
        var map = load()
        map.removeValue(forKey: id.uuidString)
        save(map)
    }

    static func clearAll() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func load() -> [String: Int] {
        UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
    }

    private static func save(_ map: [String: Int]) {
        UserDefaults.standard.set(map, forKey: key)
    }
}
