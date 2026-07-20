//
//  String+Extensions.swift
//  
//
//  Created by Reuven Levitsky on 18/09/2024.
//

import Foundation

extension String {
    
    var urlEncodedForQueryCustParamValue: String? {
        var allowedCharacters: CharacterSet = .urlQueryAllowed
        allowedCharacters.remove(charactersIn: "=&+,")
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
    
}
