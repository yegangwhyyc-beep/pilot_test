import Foundation
import TwoFactorAuth

struct Options {
    var secret: String?
    var otpauth: String?
    var digits: Int = 6
    var period: Int = 30
    var algorithm: OTPAlgorithm = .sha1
    var time: Int?
    var follow: Bool = false
    var showHelp: Bool = false
}

let usage = """
    Usage: totp [options]

    Generate a TOTP verification code from a Base32 shared secret
    (or an otpauth:// provisioning URI).

    Options:
      -s, --secret <base32>      Base32 shared secret (spaces/hyphens ignored)
      -u, --otpauth <uri>        otpauth://totp/... provisioning URI
      -d, --digits <n>           Code length, 6-8 digits (default: 6)
      -p, --period <seconds>     Time step in seconds (default: 30)
      -a, --algorithm <name>     SHA1 | SHA256 | SHA512 (default: SHA1)
      -t, --time <unix-seconds>  Generate for a fixed time instead of now
          --follow               Keep running, print a new code each period
      -h, --help                 Show this help

    Examples:
      totp --secret JBSWY3DPEHPK3PXP
      totp -u "otpauth://totp/ACME:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=ACME"
    """

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("totp: \(message)\n".utf8))
    exit(2)
}

func parseArguments() -> Options {
    var options = Options()
    let arguments = Array(CommandLine.arguments.dropFirst())

    func takeValue(_ flag: String, _ iterator: inout IndexingIterator<[String]>) -> String {
        guard let value = iterator.next(), !value.hasPrefix("-") else {
            fail("missing value for \(flag)")
        }
        return value
    }

    var iterator = arguments.makeIterator()
    while let argument = iterator.next() {
        switch argument {
        case "-h", "--help":
            options.showHelp = true
        case "-s", "--secret":
            options.secret = takeValue(argument, &iterator)
        case "-u", "--otpauth":
            options.otpauth = takeValue(argument, &iterator)
        case "-d", "--digits":
            let value = takeValue(argument, &iterator)
            guard let digits = Int(value), (6...8).contains(digits) else {
                fail("digits must be an integer between 6 and 8")
            }
            options.digits = digits
        case "-p", "--period":
            let value = takeValue(argument, &iterator)
            guard let period = Int(value), period > 0 else {
                fail("period must be a positive integer number of seconds")
            }
            options.period = period
        case "-a", "--algorithm":
            let value = takeValue(argument, &iterator)
            guard let algorithm = OTPAlgorithm(rawValue: value.uppercased()) else {
                fail("algorithm must be SHA1, SHA256 or SHA512")
            }
            options.algorithm = algorithm
        case "-t", "--time":
            let value = takeValue(argument, &iterator)
            guard let time = Int(value), time >= 0 else {
                fail("time must be a non-negative Unix timestamp in seconds")
            }
            options.time = time
        case "--follow":
            options.follow = true
        default:
            if argument.hasPrefix("-") {
                fail("unknown option '\(argument)' (see --help)")
            }
            if options.secret == nil {
                options.secret = argument
            } else {
                fail("unexpected argument '\(argument)'")
            }
        }
    }
    return options
}

var options = parseArguments()

if options.showHelp {
    print(usage)
    exit(0)
}

let label: String?
let secretData: Data
do {
    if let uriString = options.otpauth {
        let uri = try OTPAuthURI.parse(uriString)
        guard uri.kind == .totp else {
            fail("provisioning URI is HOTP; this tool generates TOTP codes")
        }
        guard let bytes = uri.secretBytes else {
            fail("provisioning URI contains an invalid Base32 secret")
        }
        secretData = bytes
        label = uri.label
        options.digits = uri.digits
        options.period = uri.period
        options.algorithm = uri.algorithm
    } else if let rawSecret = options.secret {
        let normalized = rawSecret.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard let bytes = Base32.decode(normalized), !bytes.isEmpty else {
            fail("invalid Base32 secret '\(rawSecret)'")
        }
        secretData = bytes
        label = nil
    } else {
        FileHandle.standardError.write(Data("\(usage)\n".utf8))
        exit(2)
    }
} catch let error as OTPAuthURI.ParseError {
    fail(error.description)
}

func render(at date: Date) -> String {
    let code = TOTP.generate(
        secret: secretData,
        at: date,
        period: options.period,
        digits: options.digits,
        algorithm: options.algorithm
    )
    let remaining = TOTP.secondsRemaining(at: date, period: options.period)
    if let label {
        return "\(code)  \(label)  (expires in \(remaining)s)"
    }
    return "\(code)  (expires in \(remaining)s)"
}

let initialDate: Date = options.time.map { Date(timeIntervalSince1970: TimeInterval($0)) } ?? Date()
print(render(at: initialDate))

if options.follow {
    if options.time != nil {
        fail("--follow cannot be combined with a fixed --time")
    }
    while true {
        let remaining = TOTP.secondsRemaining(period: options.period)
        Thread.sleep(forTimeInterval: TimeInterval(remaining))
        print(render(at: Date()))
    }
}
