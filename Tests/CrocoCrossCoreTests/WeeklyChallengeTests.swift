import Foundation
import XCTest
@testable import CrocoCrossCore

final class WeeklyChallengeTests: XCTestCase {
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }

    func testWeekBeginsMondayAtMidnightUTCAndEndsExclusively() {
        let monday = date("2026-09-07T00:00:00Z")
        let sunday = date("2026-09-13T23:59:59Z")
        let followingMonday = date("2026-09-14T00:00:00Z")
        let challenge = WeeklyChallenge.practice(now: monday)
        XCTAssertEqual(challenge.start, monday)
        XCTAssertEqual(challenge.end, followingMonday)
        XCTAssertEqual(WeeklyChallenge.practice(now: sunday), challenge)
        XCTAssertTrue(challenge.contains(monday))
        XCTAssertTrue(challenge.contains(sunday))
        XCTAssertFalse(challenge.contains(followingMonday))
        XCTAssertNotEqual(WeeklyChallenge.practice(now: followingMonday).seed, challenge.seed)
    }

    func testFrozenVersionedFNVFixture() {
        let challenge = WeeklyChallenge.practice(now: date("2026-09-12T22:14:00Z"))
        XCTAssertEqual(challenge.identifier, "native-3.weekly.1788739200")
        XCTAssertEqual(challenge.seed, 2_621_406_994)
        XCTAssertEqual(WeeklyChallenge.courseVersion, PhysicsConfiguration.engineVersion)
        XCTAssertEqual(WeeklyChallenge(start: challenge.start, end: challenge.end), challenge)
    }

    func testSameInstantInDifferentTimeZonesHasSameCourse() {
        let utc = WeeklyChallenge.practice(now: date("2026-09-07T00:00:00Z"))
        let california = WeeklyChallenge.practice(now: date("2026-09-06T17:00:00-07:00"))
        let kiribati = WeeklyChallenge.practice(now: date("2026-09-07T14:00:00+14:00"))
        XCTAssertEqual(california, utc)
        XCTAssertEqual(kiribati, utc)
    }

    func testDaylightSavingChangesDoNotAlterSevenDayDuration() {
        for instant in ["2026-03-08T10:00:00Z", "2026-03-29T01:00:00Z", "2026-11-01T09:00:00Z"] {
            let challenge = WeeklyChallenge.practice(now: date(instant))
            XCTAssertEqual(challenge.end.timeIntervalSince(challenge.start), 604_800)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let parts = calendar.dateComponents([.weekday, .hour, .minute, .second], from: challenge.start)
            XCTAssertEqual(parts.weekday, 2)
            XCTAssertEqual(parts.hour, 0)
            XCTAssertEqual(parts.minute, 0)
            XCTAssertEqual(parts.second, 0)
        }
    }

    func testYearBoundaryAndSerializationPreserveTheOccurrence() throws {
        let challenge = WeeklyChallenge.practice(now: date("2027-01-01T12:00:00Z"))
        XCTAssertEqual(challenge.start, date("2026-12-28T00:00:00Z"))
        XCTAssertEqual(challenge.end, date("2027-01-04T00:00:00Z"))
        let restored = try JSONDecoder().decode(WeeklyChallenge.self, from: JSONEncoder().encode(challenge))
        XCTAssertEqual(restored, challenge)
    }

    func testConfirmedScheduleRequiresSevenDayDurationAndImmediateRestart() {
        let start = date("2026-09-14T00:00:00Z")
        let end = date("2026-09-21T00:00:00Z")
        XCTAssertEqual(WeeklyChallenge.fromSchedule(start: start, duration: 604_800, nextStart: end),
                       WeeklyChallenge(start: start, end: end))
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: start, duration: 604_800,
                                                  nextStart: date("2026-09-28T00:00:00Z")), "A seven-day gap is not a weekly competition")
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: start, duration: 604_800,
                                                  nextStart: start.addingTimeInterval(86_400)), "Overlapping occurrences are invalid")
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: start, duration: 86_400, nextStart: end))
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: start, duration: 604_800, nextStart: nil))
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: nil, duration: 604_800, nextStart: end))
    }

    func testConfirmedScheduleRejectsUnanchoredAndNonfiniteMetadata() {
        for start in [date("2026-09-15T00:00:00Z"), date("2026-09-14T01:00:00Z")] {
            XCTAssertNil(WeeklyChallenge.fromSchedule(start: start, duration: 604_800,
                                                      nextStart: start.addingTimeInterval(604_800)))
        }
        let start = date("2026-09-14T00:00:00Z")
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: start, duration: .infinity,
                                                  nextStart: start.addingTimeInterval(604_800)))
        XCTAssertNil(WeeklyChallenge.fromSchedule(start: Date(timeIntervalSince1970: .nan), duration: 604_800,
                                                  nextStart: start))
    }
}
