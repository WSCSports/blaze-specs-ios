//
//  BlazeGAMError.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation

/// `BlazeGAMError` is a custom error type for handling specific ad-related errors in Google Ad Manager operations.
/// It conforms to both `Error` and `Equatable` to support error comparison and propagation.
public struct BlazeGAMError: Error, Equatable {
    
    /// Represents the specific reason for an ad-related error, encapsulated within a custom enum.
    public let reason: BlazeGAMErrorReason
    
    
    public enum BlazeGAMErrorReason: Equatable {
        /// Indicates that no ad was found and the specific error is unknown.
        case noAdFoundWithUnknownError
        
        /// Indicates an error occurred while parsing ad data.
        case failedParsingAd
    }
}
