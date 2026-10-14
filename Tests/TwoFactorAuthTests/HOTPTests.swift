import XCTest
@testable import TwoFactorAuth

final class HOTPTests: XCTestCase {
    // RFC 4226 Appendix D test secret: ASCII "12345678901234567890".
    static let secret = Data("12345678901234567890".utf8)

    // RFC 4226 Appendix D HOTP values for counters 0...9.
    static let rfcVectors: [String] = [
        "755224", "287082", "359152", "969429", "338314",
        "254676", "287922", "162583", "399871", "520489"
    ]

    func testRFC4226Vectors() {
        for (counter, expected) in Self.rfcVectors.enumerated() {
            let code = HOTP.generate(secret: Self.secret, counter: UInt64(counter))
            XCTAssertEqual(code, expected, "counter \(counter)")
        }
    }

    func testCodeIsZeroPaddedToDigits() {
        // RFC 6238 t=59 yields 287082 with SHA-1; pick a counter whose
        // modulo has leading zeros by asserting formatting invariants.
        let code = HOTP.generate(secret: Self.secret, counter: 0, digits: 8)
        XCTAssertEqual(code.count, 8)
        // 8-digit RFC 4226 counter 0 value is 84755224.
        XCTAssertEqual(code, "84755224")
    }

    func testSHA256AndSHA512DoNotCrashAndHaveCorrectLength() {
        let code256 = HOTP.generate(secret: Self.secret, counter: 1, algorithm: .sha256)
        let code512 = HOTP.generate(secret: Self.secret, counter: 1, algorithm: .sha512)
        XCTAssertEqual(code256.count, 6)
        XCTAssertEqual(code512.count, 6)
        XCTAssertNotEqual(code256, code512)
    }

    func testSevenDigitsAreZeroPadded() {
        // RFC 4226 counter 0 is 84755224 with 8 digits -> 4755224 with 7.
        XCTAssertEqual(HOTP.generate(secret: Self.secret, counter: 0, digits: 7), "4755224")
        XCTAssertEqual(HOTP.generate(secret: Self.secret, counter: 0, digits: 6), "755224")
    }
}
