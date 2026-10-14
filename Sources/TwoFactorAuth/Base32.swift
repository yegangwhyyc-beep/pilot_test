import Foundation

/// RFC 4648 Base32 codec used for OTP shared secrets.
public enum Base32 {
    private static let alphabet = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
    private static let decodeTable: [UInt8: UInt8] = {
        var table: [UInt8: UInt8] = [:]
        for (index, character) in alphabet.enumerated() {
            table[UInt8(character.asciiValue!)] = UInt8(index)
        }
        return table
    }()

    /// Decodes a Base32 string. Decoding is case-insensitive and tolerates
    /// whitespace, hyphens and missing/extra padding.
    public static func decode(_ string: String) -> Data? {
        var bitBuffer: UInt32 = 0
        var bitCount: UInt32 = 0
        var output = Data()
        output.reserveCapacity(string.count * 5 / 8)

        for scalar in string.uppercased().unicodeScalars {
            if CharacterSet.whitespacesAndNewlines.contains(scalar) || scalar == "-" {
                continue
            }
            if scalar == "=" {
                continue
            }
            guard let value = decodeTable[UInt8(scalar.value)] else {
                return nil
            }
            bitBuffer = (bitBuffer << 5) | UInt32(value)
            bitCount += 5
            if bitCount >= 8 {
                bitCount -= 8
                output.append(UInt8((bitBuffer >> bitCount) & 0xFF))
            }
        }
        return output
    }

    /// Encodes data as unpadded Base32, the form normally used in otpauth URIs.
    public static func encode(_ data: Data) -> String {
        var output = ""
        var bitBuffer: UInt32 = 0
        var bitCount: UInt32 = 0

        for byte in data {
            bitBuffer = (bitBuffer << 8) | UInt32(byte)
            bitCount += 8
            while bitCount >= 5 {
                bitCount -= 5
                let index = Int((bitBuffer >> bitCount) & 0x1F)
                output.append(alphabet[index])
            }
        }
        if bitCount > 0 {
            let index = Int((bitBuffer << (5 - bitCount)) & 0x1F)
            output.append(alphabet[index])
        }
        return output
    }
}
