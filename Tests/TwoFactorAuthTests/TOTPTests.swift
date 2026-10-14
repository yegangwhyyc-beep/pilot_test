import XCTest
@testable import TwoFactorAuth

final class TOTPTests: XCTestCase {
    // RFC 6238 Appendix B SHA-1 secret: ASCII "12345678901234567890".
    static let secret = Data("12345678901234567890".utf8)

    // RFC 6238 Appendix B, 8-digit SHA-1 expected values.
    static let rfcVectors: [(Int64, String)] = [
        (59, "94287082"),
        (1111111109, "07081804"),
        (1111111111, "14050471"),
        (1234567890, "89005924")
    ]

    func testRFC6238VectorsSHA1() {
        for (timestamp, expected) in Self.rfcVectors {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
            let code = TOTP.generate(secret: Self.secret, at: date, digits: 8)
            XCTAssertEqual(code, expected, "timestamp \(timestamp)")
        }
    }

    func testDefaultPeriodIs30Seconds() {
        // t=59 and t=0 fall in different steps; t=29 and t=0 share a step.
        let codeAt0 = TOTP.generate(secret: Self.secret, at: Date(timeIntervalSince1970: 0))
        let codeAt29 = TOTP.generate(secret: Self.secret, at: Date(timeIntervalSince1970: 29))
        let codeAt30 = TOTP.generate(secret: Self.secret, at: Date(timeIntervalSince1970: 30))
        XCTAssertEqual(codeAt0, codeAt29)
        XCTAssertNotEqual(codeAt0, codeAt30)
    }

    func testSecondsRemaining() {
        XCTAssertEqual(TOTP.secondsRemaining(at: Date(timeIntervalSince1970: 0)), 30)
        XCTAssertEqual(TOTP.secondsRemaining(at: Date(timeIntervalSince1970: 29)), 1)
        XCTAssertEqual(TOTP.secondsRemaining(at: Date(timeIntervalSince1970: 30)), 30)
        XCTAssertEqual(
            TOTP.secondsRemaining(at: Date(timeIntervalSince1970: 61), period: 60),
            59
        )
    }

    func testRFC6238VectorsSHA256AndSHA512() {
        let secret256 = Data("12345678901234567890123456789012".utf8)
        let secret512 = Data("1234567890123456789012345678901234567890123456789012345678901234".utf8)
        let date = Date(timeIntervalSince1970: 59)
        XCTAssertEqual(
            TOTP.generate(secret: secret256, at: date, digits: 8, algorithm: .sha256),
            "46119246"
        )
        XCTAssertEqual(
            TOTP.generate(secret: secret512, at: date, digits: 8, algorithm: .sha512),
            "90693936"
        )
    }

    func testCustomPeriodAndDigits() {
        let date = Date(timeIntervalSince1970: 59)
        let code = TOTP.generate(secret: Self.secret, at: date, period: 60, digits: 8)
        // Counter = 59/60 = 0 -> HOTP counter 0 with 8 digits per RFC 4226.
        XCTAssertEqual(code, "84755224")
    }
}
