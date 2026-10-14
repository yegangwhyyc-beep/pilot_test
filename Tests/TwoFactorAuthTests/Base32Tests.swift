import XCTest
@testable import TwoFactorAuth

final class Base32Tests: XCTestCase {
    // RFC 4648 Section 10 test vectors.
    func testRFC4648DecodeVectors() {
        let vectors: [(String, String)] = [
            ("", ""),
            ("MY======", "f"),
            ("MZXQ====", "fo"),
            ("MZXW6===", "foo"),
            ("MZXW6YQ=", "foob"),
            ("MZXW6YTB", "fooba"),
            ("MZXW6YTBOI======", "foobar")
        ]
        for (encoded, expected) in vectors {
            XCTAssertEqual(Base32.decode(encoded), Data(expected.utf8), encoded)
        }
    }

    func testDecodeIsCaseInsensitiveAndPaddingTolerant() {
        XCTAssertEqual(Base32.decode("mzxw6ytb"), Data("fooba".utf8))
        XCTAssertEqual(Base32.decode("mzxw6ytboi"), Data("foobar".utf8))
        XCTAssertEqual(Base32.decode("JBSW Y3DP-EHPK 3PXP"), Base32.decode("JBSWY3DPEHPK3PXP"))
    }

    func testRejectsInvalidCharacters() {
        XCTAssertNil(Base32.decode("MZXW6YTB0"))
        XCTAssertNil(Base32.decode("***"))
    }

    func testEncodeVectors() {
        XCTAssertEqual(Base32.encode(Data()), "")
        XCTAssertEqual(Base32.encode(Data("f".utf8)), "MY")
        XCTAssertEqual(Base32.encode(Data("fo".utf8)), "MZXQ")
        XCTAssertEqual(Base32.encode(Data("foo".utf8)), "MZXW6")
        XCTAssertEqual(Base32.encode(Data("foob".utf8)), "MZXW6YQ")
        XCTAssertEqual(Base32.encode(Data("fooba".utf8)), "MZXW6YTB")
        XCTAssertEqual(Base32.encode(Data("foobar".utf8)), "MZXW6YTBOI")
    }

    func testRoundTrip() {
        let original = Data([0x00, 0x01, 0x02, 0xFE, 0xFF, 0x10, 0x7F, 0x80])
        XCTAssertEqual(Base32.decode(Base32.encode(original)), original)
    }

    func testCommonOTPSecretDecodesToTenBytes() {
        // "JBSWY3DPEHPK3PXP" decodes to ASCII "Hello!" followed by DE AD BE EF,
        // the canonical Base32 example used throughout TOTP documentation.
        let bytes = Base32.decode("JBSWY3DPEHPK3PXP")
        XCTAssertEqual(bytes, Data([0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x21, 0xDE, 0xAD, 0xBE, 0xEF]))
    }
}
