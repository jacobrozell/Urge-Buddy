import XCTest
@testable import UrgeBuddy

final class TriggerTagTests: XCTestCase {
    func testEncodeDecodeRoundTrip() {
        let tags: [TriggerTag] = [.tired, .routine, .lonely]
        XCTAssertEqual(TriggerTag.decode(TriggerTag.encode(tags)), tags)
    }

    func testUnknownRawValuesAreDropped() {
        XCTAssertEqual(TriggerTag.decode("tired|nope|bored|"), [.tired, .bored])
    }

    func testEmptyStringDecodesToNoTags() {
        XCTAssertEqual(TriggerTag.decode(""), [])
    }

    func testEveryTagHasATitleImageAndStableID() {
        for tag in TriggerTag.allCases {
            XCTAssertFalse(tag.title.isEmpty)
            XCTAssertFalse(tag.systemImage.isEmpty)
            XCTAssertEqual(tag.id, tag.rawValue)
        }
    }
}
