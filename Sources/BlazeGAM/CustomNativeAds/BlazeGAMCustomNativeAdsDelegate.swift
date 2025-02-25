//
//  BlazeGAMCustomNativeAdsDelegate.swift
//  
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import BlazeSDK
import GoogleMobileAds

/// The `BlazeGAMCustomNativeAdsDelegate` struct defines a set of methods that a delegate of the `BlazeGAM` class can adopt.
/// The delegate methods provide callbacks for ad-related events and errors, allowing custom handling of these situations in the application.
public struct BlazeGAMCustomNativeAdsDelegate {
    
    public struct RequestDataInfo {
        public let requestDataInfo: BlazeGamCustomNativeAdRequestInformation
    }
    
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
     - Parameters:
        -  params: The request data information provides additional  info regarding the current ad request.
     
     - Returns: key-value pairs relevant to the ad targeting logic such as user demographics, behavior or other relevant advertising criteria.
     */
    public typealias CustomGAMTargetingPropertiesHandler = (_ params: RequestDataInfo) -> [String : String]
    
    /**
     - Parameters:
        -  params: The request data information provides additional  info regarding the current ad request.
     
     - Returns: A custom publisher-provided identifier (PPID) for more granular targeting.
     */
    public typealias PublisherProvidedIdHandler = (_ params: RequestDataInfo) -> String?
    
    /**
     - Parameters:
        -  params: The request data information provides additional  info regarding the current ad request.
     
     - Returns: Additional network extras object of type GADExtras for configuring ad requests with custom parameters.
     */
    public typealias NetworkExtrasHandler = (_ params: RequestDataInfo) -> GADExtras?
    
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
    
    /// Provides a custom publisher-provided identifier (PPID) for ad requests.
    ///
    /// Example implementation:
    /// ```
    /// publisherProvidedId {
    ///     return "user12345"
    /// }
    /// ```
    public var publisherProvidedId: PublisherProvidedIdHandler?
    
    /// Provides additional network extras through GADExtras for customizing ad requests.
    /// Use this to set network-specific parameters that can enhance ad targeting or behavior.
    ///
    /// Example implementation:
    /// ```
    /// networkExtras {
    ///     let extras = GADExtras()
    ///     extras.additionalParameters = ["key1": "value1", "key2": 1234]
    ///     return extras
    /// }
    /// ```
    public var networkExtras: NetworkExtrasHandler?
    
    public init(onGAMAdError: OnGAMAdErrorHandler? = nil,
                onGAMAdEvent: OnGAMAdEventHandler? = nil,
                customGAMTargetingProperties: CustomGAMTargetingPropertiesHandler? = nil,
                publisherProvidedId: PublisherProvidedIdHandler? = nil,
                networkExtras: NetworkExtrasHandler? = nil) {
        self.onGAMAdError = onGAMAdError
        self.onGAMAdEvent = onGAMAdEvent
        self.customGAMTargetingProperties = customGAMTargetingProperties
        self.publisherProvidedId = publisherProvidedId
        self.networkExtras = networkExtras
    }
}

//MARK: Intenal default implementations
extension BlazeGAMCustomNativeAdsDelegate {
    
    internal var customGAMTargetingPropertiesOrDefault: CustomGAMTargetingPropertiesHandler {
        let defaultImpl: CustomGAMTargetingPropertiesHandler = { params in
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
