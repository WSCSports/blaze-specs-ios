//
//  BlazeGAMBannerAdsDelegate.swift
//  
//
//  Created by Reuven Levitsky on 08/08/2024.
//

import Foundation
import BlazeSDK

/// A struct that defines a set of methods that a delegate of the `BlazeGAM` class can adopt.
/// The delegate methods provide callbacks for ad-related events and errors, allowing custom handling of these situations in the application.
public struct BlazeGAMBannerAdsDelegate {
    
    /**
     - error: The error that occurred.
     */
    public typealias OnGAMBannerAdsAdErrorHandler = ((error: Error, adData: BlazeGAMBannerAdsAdData)) -> Void
    
    /**
     - eventType: The type of event that occurred, as defined by `BlazeGAMBannerHandlerEventType`.
     - adData: The data associated with the ad involved in the event.
     */
    public typealias OnGAMBannerAdsAdEventHandler = ((eventType: BlazeGAMBannerHandlerEventType, adData: BlazeGAMBannerAdsAdData)) -> Void
    
    /// Called when an error occurs during ad operations.
    public var onGAMBannerAdsAdError: OnGAMBannerAdsAdErrorHandler?
    
    /// Called when an ad-related event occurs, providing details about the event and ad data.
    public var onGAMBannerAdsAdEvent: OnGAMBannerAdsAdEventHandler?
    
    public init(onGAMBannerAdsAdError: OnGAMBannerAdsAdErrorHandler? = nil,
                onGAMBannerAdsAdEvent: OnGAMBannerAdsAdEventHandler? = nil) {
        self.onGAMBannerAdsAdError = onGAMBannerAdsAdError
        self.onGAMBannerAdsAdEvent = onGAMBannerAdsAdEvent
    }
}
