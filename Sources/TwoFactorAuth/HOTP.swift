import Foundation
import Crypto

/// Hash algorithms supported by the OTP specifications.
public enum OTPAlgorithm: String, CaseIterable, Sendable {
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

public enum HOTP {
    /// Generates an HOTP code (RFC 4226).
    ///
    /// - Parameters:
    ///   - secret: shared secret key bytes.
    ///   - counter: 8-byte moving factor.
    ///   - digits: number of digits (6...8 per RFC 4226).
    ///   - algorithm: HMAC hash algorithm.
    public static func generate(
        secret: Data,
        counter: UInt64,
        digits: Int = 6,
        algorithm: OTPAlgorithm = .sha1
    ) -> String {
        precondition((6...8).contains(digits), "digits must be between 6 and 8")

        var counterBigEndian = counter.bigEndian
        let counterData = Data(bytes: &counterBigEndian, count: MemoryLayout<UInt64>.size)

        let key = SymmetricKey(data: secret)
        let mac: Data
        switch algorithm {
        case .sha1:
            mac = Data(HMAC<Insecure.SHA1>.authenticationCode(for: counterData, using: key))
        case .sha256:
            mac = Data(HMAC<SHA256>.authenticationCode(for: counterData, using: key))
        case .sha512:
            mac = Data(HMAC<SHA512>.authenticationCode(for: counterData, using: key))
        }

        return truncate(mac: mac, digits: digits)
    }

    static func truncate(mac: Data, digits: Int) -> String {
        let offset = Int(mac[mac.count - 1] & 0x0F)
        let binary =
            (UInt32(mac[offset] & 0x7F) << 24)
            | (UInt32(mac[offset + 1] & 0xFF) << 16)
            | (UInt32(mac[offset + 2] & 0xFF) << 8)
            | UInt32(mac[offset + 3] & 0xFF)

        var modulo: UInt32 = 1
        for _ in 0..<digits {
            modulo &*= 10
        }
        let value = binary % modulo
        let text = String(value)
        return String(repeating: "0", count: max(0, digits - text.count)) + text
    }
}
