@testable import Ghostty
import Foundation
import Testing

struct SurfaceViewAccessibilityTests {
    @Test func accessibilityRangeFindsLoneOccurrence() {
        let range = Ghostty.SurfaceView.accessibilityRange(
            of: "selected",
            in: "before selected after")
        #expect(range == NSRange(location: 7, length: 8))
    }

    @Test func accessibilityRangeRejectsMultipleMatches() {
        // `ls\n` appears twice in the haystack.
        let range = Ghostty.SurfaceView.accessibilityRange(
            of: "ls\n",
            in: "$ ls\nfoo bar\n$ ls\nbaz")
        #expect(range.location == NSNotFound)
        #expect(range.length == 0)
    }

    @Test(arguments: [
        "nope",  // absent
        "",      // empty
    ])
    func accessibilityRangeReturnsNotFoundForBadNeedle(needle: String) {
        let range = Ghostty.SurfaceView.accessibilityRange(of: needle, in: "haystack")
        #expect(range.location == NSNotFound)
        #expect(range.length == 0)
    }

    @Test func accessibilityRangeHandlesSupplementaryPlane() {
        // "😀" is two UTF-16 units (surrogate pair).
        let range = Ghostty.SurfaceView.accessibilityRange(
            of: "😀",
            in: "x😀y")
        #expect(range == NSRange(location: 1, length: 2))
    }
}
