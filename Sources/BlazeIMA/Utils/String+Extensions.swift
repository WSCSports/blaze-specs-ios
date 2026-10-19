//
//  String+Extensions.swift
//  
//
//  Created by Reuven Levitsky on 18/09/2024.
//

import Foundation

/// Cached character sets and literals for `sanitizedAdTagURL`, avoiding per-call rebuilds.
private enum AdTagSanitization {
    static let extraLegalCharacters = ":/?#@!$&'()*+,;="
    /// Legal path/query/fragment characters; `[`/`]` excluded (macro leftovers).
    static let legalCharacters = CharacterSet.urlQueryAllowed
        .union(CharacterSet(charactersIn: extraLegalCharacters))
    static let authoritySeparator = "://"
    static let authorityTerminators: Set<Character> = ["/", "?", "#"]
}

extension String {

    private static let queryCustParamValueDisallowedCharacters = "=&+,"

    var urlEncodedForQueryCustParamValue: String? {
        var allowedCharacters: CharacterSet = .urlQueryAllowed
        allowedCharacters.remove(charactersIn: Self.queryCustParamValueDisallowedCharacters)
        let encodedValue = addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        return encodedValue
    }

    var isValidAdTagURL: Bool {
        guard !isEmpty,
              let components = URLComponents(string: self),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty else {
            return false
        }
        return true
    }

    /// True when the string already round-trips through `URLComponents`
    /// byte-for-byte (e.g. IPv6 host `[::1]`) — no sanitization needed (D-6).
    private var isRoundTrippableURL: Bool {
        guard let components = URLComponents(string: self) else { return false }
        return components.url?.absoluteString == self
    }

    /// Offset (in Characters) of the first char after the authority
    /// (scheme://host:port), so host brackets like `[::1]` aren't encoded.
    /// Returns 0 when no scheme separator is present.
    private func authorityEndOffset(of chars: [Character]) -> Int {
        var scanStart = 0
        if let schemeRange = range(of: AdTagSanitization.authoritySeparator) {
            let afterScheme = distance(from: startIndex, to: schemeRange.upperBound)
            scanStart = afterScheme
            while scanStart < chars.count {
                let c = chars[scanStart]
                if AdTagSanitization.authorityTerminators.contains(c) { break }
                scanStart += 1
            }
        }
        return scanStart
    }

    /// Percent-encodes illegal characters, copying well-formed %XX escapes
    /// through unchanged (D-5: never double-encode).
    private static func percentEncodingIllegalCharacters(in chars: ArraySlice<Character>) -> String {
        var result = ""
        var i = chars.startIndex
        while i < chars.endIndex {
            let char = chars[i]
            if char == "%",
               i + 2 < chars.endIndex,
               chars[i + 1].isHexDigit, chars[i + 2].isHexDigit {
                // Already percent-escaped (e.g. %20, %5B) - copy through unchanged.
                result.append(char)
                result.append(chars[i + 1])
                result.append(chars[i + 2])
                i += 3
                continue
            }
            if char.unicodeScalars.allSatisfy({ AdTagSanitization.legalCharacters.contains($0) }) {
                result.append(char)
            } else {
                result += String(char).utf8.map { String(format: "%%%02X", $0) }.joined()
            }
            i += 1
        }
        return result
    }

    /// Percent-encodes RFC 3986-illegal characters (spaces, `[`, `]`, etc.) left over from
    /// unsubstituted VAST macros, so the tag can be parsed by `URLComponents` and accepted by IMA.
    var sanitizedAdTagURL: String {
        guard !isEmpty else { return self }

        if isRoundTrippableURL { return self }

        var result = ""
        result.reserveCapacity(count)
        let chars = Array(self)

        // Skip the authority (scheme+host+port) so IPv6 host brackets like `[::1]` aren't encoded.
        let scanStart = authorityEndOffset(of: chars)
        result.append(contentsOf: chars[0..<scanStart])
        result += Self.percentEncodingIllegalCharacters(in: chars[scanStart...])
        return result
    }

}
