import Foundation

public enum TOTP {
    /// Generates a TOTP code (RFC 6238).
    ///
    /// - Parameters:
    ///   - secret: shared secret key bytes.
    ///   - date: time to generate the code for (defaults to now).
    ///   - period: time step in seconds (RFC default 30).
    ///   - digits: number of digits (6...8).
    ///   - algorithm: HMAC hash algorithm.
    public static func generate(
        secret: Data,
        at date: Date = Date(),
        period: Int = 30,
        digits: Int = 6,
        algorithm: OTPAlgorithm = .sha1
    ) -> String {
        precondition(period > 0, "period must be positive")
        let counter = UInt64(date.timeIntervalSince1970) / UInt64(period)
        return HOTP.generate(secret: secret, counter: counter, digits: digits, algorithm: algorithm)
    }

    /// Seconds remaining in the current time step.
    public static func secondsRemaining(at date: Date = Date(), period: Int = 30) -> Int {
        precondition(period > 0, "period must be positive")
        let elapsed = Int(date.timeIntervalSince1970) % period
        return period - elapsed
    }
}
