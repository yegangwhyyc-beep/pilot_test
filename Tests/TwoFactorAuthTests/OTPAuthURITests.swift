import XCTest
@testable import TwoFactorAuth

final class OTPAuthURITests: XCTestCase {
    func testParsesMinimalTOTPURI() throws {
        let uri = try OTPAuthURI.parse("otpauth://totp/ACME:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME")
        XCTAssertEqual(uri.kind, .totp)
        XCTAssertEqual(uri.label, "ACME:alice@example.com")
        XCTAssertEqual(uri.issuer, "ACME")
        XCTAssertEqual(uri.accountName, "alice@example.com")
        XCTAssertEqual(uri.secret, "JBSWY3DPEHPK3PXP")
        XCTAssertEqual(uri.algorithm, .sha1)
        XCTAssertEqual(uri.digits, 6)
        XCTAssertEqual(uri.period, 30)
        XCTAssertNotNil(uri.secretBytes)
    }

    func testParsesAllParameters() throws {
        let uri = try OTPAuthURI.parse(
            "otpauth://totp/Example:user?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA256&digits=8&period=60"
        )
        XCTAssertEqual(uri.algorithm, .sha256)
        XCTAssertEqual(uri.digits, 8)
        XCTAssertEqual(uri.period, 60)
    }

    func testLabelWithoutIssuerPrefix() throws {
        let uri = try OTPAuthURI.parse("otpauth://totp/alice?secret=JBSWY3DPEHPK3PXP")
        XCTAssertEqual(uri.accountName, "alice")
        XCTAssertNil(uri.issuer)
    }

    func testPercentEncodedLabel() throws {
        let uri = try OTPAuthURI.parse("otpauth://totp/ACME%20Co:alice%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME%20Co")
        XCTAssertEqual(uri.label, "ACME Co:alice@example.com")
        XCTAssertEqual(uri.issuer, "ACME Co")
    }

    func testParsesHOTPWithCounter() throws {
        let uri = try OTPAuthURI.parse("otpauth://hotp/ACME:alice?secret=JBSWY3DPEHPK3PXP&counter=42")
        XCTAssertEqual(uri.kind, .hotp)
        XCTAssertEqual(uri.counter, 42)
    }

    func testRejectsInvalidScheme() {
        XCTAssertThrowsError(try OTPAuthURI.parse("http://totp/x?secret=A")) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .invalidScheme)
        }
        XCTAssertThrowsError(try OTPAuthURI.parse("not a uri")) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .invalidScheme)
        }
    }

    func testRejectsMissingSecret() {
        XCTAssertThrowsError(try OTPAuthURI.parse("otpauth://totp/alice")) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .missingSecret)
        }
    }

    func testRejectsMissingLabel() {
        XCTAssertThrowsError(try OTPAuthURI.parse("otpauth://totp/?secret=JBSWY3DPEHPK3PXP")) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .missingLabel)
        }
    }

    func testRejectsHOTPWithoutCounter() {
        XCTAssertThrowsError(
            try OTPAuthURI.parse("otpauth://hotp/alice?secret=JBSWY3DPEHPK3PXP")
        ) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .missingCounter)
        }
    }

    func testRejectsBadParameters() {
        XCTAssertThrowsError(
            try OTPAuthURI.parse("otpauth://totp/alice?secret=JBSWY3DPEHPK3PXP&digits=5")
        ) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .invalidDigits("5"))
        }
        XCTAssertThrowsError(
            try OTPAuthURI.parse("otpauth://totp/alice?secret=JBSWY3DPEHPK3PXP&period=0")
        ) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .invalidPeriod("0"))
        }
        XCTAssertThrowsError(
            try OTPAuthURI.parse("otpauth://totp/alice?secret=JBSWY3DPEHPK3PXP&algorithm=MD5")
        ) { error in
            XCTAssertEqual(error as? OTPAuthURI.ParseError, .invalidAlgorithm("MD5"))
        }
    }
}
