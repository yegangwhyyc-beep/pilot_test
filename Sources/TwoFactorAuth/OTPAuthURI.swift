import Foundation

/// A parsed `otpauth://` provisioning URI as used by QR codes
/// (Google Authenticator key URI format).
public struct OTPAuthURI: Equatable, Sendable {
    public enum Kind: String, Sendable {
        case totp
        case hotp
    }

    public var kind: Kind
    public var label: String
    public var issuer: String?
    public var accountName: String?
    public var secret: String
    public var issuerParameter: String?
    public var algorithm: OTPAlgorithm
    public var digits: Int
    public var period: Int
    public var counter: UInt64?

    /// Decoded shared-secret bytes. Nil when the secret is not valid Base32.
    public var secretBytes: Data? { Base32.decode(secret) }

    /// Splits the label into issuer and account when it contains a colon.
    public static func splitLabel(_ label: String) -> (issuer: String?, account: String?) {
        guard let range = label.range(of: ":") else {
            return (nil, label.isEmpty ? nil : label)
        }
        let issuer = String(label[label.startIndex..<range.lowerBound])
        let account = String(label[range.upperBound...])
        return (issuer.isEmpty ? nil : issuer, account.isEmpty ? nil : account)
    }

    public init(
        kind: Kind,
        label: String,
        secret: String,
        issuerParameter: String? = nil,
        algorithm: OTPAlgorithm = .sha1,
        digits: Int = 6,
        period: Int = 30,
        counter: UInt64? = nil
    ) {
        self.kind = kind
        self.label = label
        self.secret = secret
        self.issuerParameter = issuerParameter
        self.algorithm = algorithm
        self.digits = digits
        self.period = period
        self.counter = counter

        let parts = Self.splitLabel(label)
        self.accountName = parts.account
        self.issuer = issuerParameter ?? parts.issuer
    }

    public enum ParseError: Error, Equatable, CustomStringConvertible {
        case invalidScheme
        case unsupportedType(String)
        case missingLabel
        case missingSecret
        case invalidDigits(String)
        case invalidPeriod(String)
        case invalidAlgorithm(String)
        case invalidCounter
        case missingCounter

        public var description: String {
            switch self {
            case .invalidScheme: return "URI must start with otpauth://"
            case .unsupportedType(let type): return "unsupported OTP type '\(type)' (expected totp or hotp)"
            case .missingLabel: return "otpauth URI is missing the account label"
            case .missingSecret: return "otpauth URI is missing the 'secret' parameter"
            case .invalidDigits(let value): return "invalid digits value '\(value)'"
            case .invalidPeriod(let value): return "invalid period value '\(value)'"
            case .invalidAlgorithm(let value): return "unsupported algorithm '\(value)' (expected SHA1, SHA256 or SHA512)"
            case .invalidCounter: return "invalid counter value"
            case .missingCounter: return "hotp URI requires a 'counter' parameter"
            }
        }
    }

    public static func parse(_ string: String) throws -> OTPAuthURI {
        guard let url = URL(string: string),
              url.scheme == "otpauth",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw ParseError.invalidScheme
        }

        let type = components.host ?? ""
        guard let kind = Kind(rawValue: type) else {
            throw ParseError.unsupportedType(type)
        }

        // URLComponents.path already percent-decodes the path component.
        let label = components.path
        let decodedLabel = label.hasPrefix("/") ? String(label.dropFirst()) : label
        guard !decodedLabel.isEmpty else {
            throw ParseError.missingLabel
        }

        let queryItems = components.queryItems ?? []
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name.lowercased()] = value
            }
        }

        guard let secret = params["secret"], !secret.isEmpty else {
            throw ParseError.missingSecret
        }

        let algorithm: OTPAlgorithm
        if let raw = params["algorithm"] {
            guard let parsed = OTPAlgorithm(rawValue: raw.uppercased()) else {
                throw ParseError.invalidAlgorithm(raw)
            }
            algorithm = parsed
        } else {
            algorithm = .sha1
        }

        var digits = 6
        if let raw = params["digits"] {
            guard let value = Int(raw), (6...8).contains(value) else {
                throw ParseError.invalidDigits(raw)
            }
            digits = value
        }

        var period = 30
        if let raw = params["period"] {
            guard let value = Int(raw), value > 0 else {
                throw ParseError.invalidPeriod(raw)
            }
            period = value
        }

        var counter: UInt64?
        if let raw = params["counter"] {
            guard let value = UInt64(raw) else {
                throw ParseError.invalidCounter
            }
            counter = value
        } else if kind == .hotp {
            throw ParseError.missingCounter
        }

        return OTPAuthURI(
            kind: kind,
            label: decodedLabel,
            secret: secret,
            issuerParameter: params["issuer"],
            algorithm: algorithm,
            digits: digits,
            period: period,
            counter: counter
        )
    }
}
