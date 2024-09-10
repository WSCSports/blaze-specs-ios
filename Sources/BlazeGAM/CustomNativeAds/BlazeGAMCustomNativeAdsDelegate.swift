//
//  BlazeGAMCustomNativeAdsDelegate.swift
//  
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import BlazeSDK

/// The `BlazeGAMCustomNativeAdsDelegate` struct defines a set of methods that a delegate of the `BlazeGAM` class can adopt.
/// The delegate methods provide callbacks for ad-related events and errors, allowing custom handling of these situations in the application.
public struct BlazeGAMCustomNativeAdsDelegate {
    
    /**
     - error: The error that occurred.
     */
    public typealias OnGAMAdErrorHandler = (_ error: Error) -> Void
    
    /**
     - eventType: The type of event that occurred, as defined by `BlazeGoogleCustomNativeAdsHandlerEventType`.
     - adData: The data associated with the ad involved in the event.
     */
    public typealias OnGAMAdEventHandler = ((eventType: BlazeGoogleCustomNativeAdsHandlerEventType, adData: BlazeCustomNativeAdData)) -> Void
    
    /**
     - Returns: key-value pairs relevant to the ad targeting logic such as user demographics, behavior or other relevant advertising criteria.
     */
    public typealias CustomGAMTargetingPropertiesHandler = () -> [String : String]
    
    /// Called when an error occurs during ad operations.
    public var onGAMAdError: OnGAMAdErrorHandler?
    
    /// Called when an ad-related event occurs, providing details about the event and ad data.
    public var onGAMAdEvent: OnGAMAdEventHandler?
    
    /// Specifies custom targeting properties to be used in ad requests. This dictionary can include any key-value pairs
    /// relevant to the ad targeting logic such as user demographics, behavior or other relevant advertising criteria.
    /// Example implementation:
    /// ```
    /// customGAMTargetingProperties {
    ///     return ["userAge": "25", "interests": "technology"]
    /// }
    /// ```
    public var customGAMTargetingProperties: CustomGAMTargetingPropertiesHandler?
    
    public init(onGAMAdError: OnGAMAdErrorHandler? = nil,
                onGAMAdEvent: OnGAMAdEventHandler? = nil,
                customGAMTargetingProperties: CustomGAMTargetingPropertiesHandler? = nil) {
        self.onGAMAdError = onGAMAdError
        self.onGAMAdEvent = onGAMAdEvent
        self.customGAMTargetingProperties = customGAMTargetingProperties
    }
}

//MARK: Intenal default implementations
extension BlazeGAMCustomNativeAdsDelegate {
    
    internal var customGAMTargetingPropertiesOrDefault: CustomGAMTargetingPropertiesHandler {
        let defaultImpl: CustomGAMTargetingPropertiesHandler = {
            return [:]
        }
        return customGAMTargetingProperties ?? defaultImpl
    }
}


/// The `BlazeGAMDelegate` struct defines a set of methods that a delegate of the `BlazeGAM` class can adopt.
/// The delegate methods provide callbacks for ad-related events and errors, allowing custom handling of these situations in the application.
@available(*, unavailable, renamed: "BlazeGAMCustomNativeAdsDelegate")
public struct BlazeGAMDelegate {
    
    /**
     - error: The error that occurred.
     */
    public typealias OnGAMAdErrorHandler = (_ error: Error) -> Void
    
    /**
     - eventType: The type of event that occurred, as defined by `BlazeGoogleCustomNativeAdsHandlerEventType`.
     - adData: The data associated with the ad involved in the event.
     */
    public typealias OnGAMAdEventHandler = ((eventType: BlazeGoogleCustomNativeAdsHandlerEventType, adData: BlazeCustomAdData)) -> Void
    
    /**
     - Returns: key-value pairs relevant to the ad targeting logic such as user demographics, behavior or other relevant advertising criteria.
     */
    public typealias CustomGAMTargetingPropertiesHandler = () -> [String : String]
    
    /// Called when an error occurs during ad operations.
    public var onGAMAdError: OnGAMAdErrorHandler?
    
    /// Called when an ad-related event occurs, providing details about the event and ad data.
    public var onGAMAdEvent: OnGAMAdEventHandler?
    
    /// Specifies custom targeting properties to be used in ad requests. This dictionary can include any key-value pairs
    /// relevant to the ad targeting logic such as user demographics, behavior or other relevant advertising criteria.
    /// Example implementation:
    /// ```
    /// customGAMTargetingProperties {
    ///     return ["userAge": "25", "interests": "technology"]
    /// }
    /// ```
    public var customGAMTargetingProperties: CustomGAMTargetingPropertiesHandler?
    
    public init(onGAMAdError: OnGAMAdErrorHandler? = nil,
                onGAMAdEvent: OnGAMAdEventHandler? = nil,
                customGAMTargetingProperties: CustomGAMTargetingPropertiesHandler? = nil) {
        self.onGAMAdError = onGAMAdError
        self.onGAMAdEvent = onGAMAdEvent
        self.customGAMTargetingProperties = customGAMTargetingProperties
    }
}
