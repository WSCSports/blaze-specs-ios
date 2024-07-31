//
//  BlazeIMAAppDelegate.swift
//
//
//  Created by Dor Zafrir on 13/06/2024.
//

import Foundation
import BlazeSDK
import GoogleInteractiveMediaAds

/// A struct that defines the delegate methods for handling IMA (Interactive Media Ads) events.
/// Implement this protocol to receive notifications about ad errors and events, as well as to provide additional
/// query parameters and custom settings for the IMA SDK.
public struct BlazeIMADelegate {
    
    /**
     - message: A string describing the error that occurred.
     */
    public typealias OnIMAAdErrorHandler = (_ message: String) -> Void
    
    /**
     - eventType: is the event type triggered.
     - adInfo: is the info for the ad
     */
    public typealias OnIMAAdEventHandler = ((eventType: BlazeIMAHandlerEventType, adInfo: BlazeImaAdInfo)) -> Void
    
    /**
     - Returns: Additional query parameters to be included in the ad tag.
     */
    public typealias AdditionalIMATagQueryParamsHandler = () -> [String : String]
    
    /**
     - Returns: Custom settings for the IMA SDK.
     */
    public typealias CustomIMASettingsHandler = () -> IMASettings?
    
    
    /// Called when an error occurs during ad loading or playback.
    public var onIMAAdError: OnIMAAdErrorHandler?
    
    /// This function will be triggered every time an event on an ad will happen.
    /// Here you can implement for example handling clicks, impression, or just log the events.
    public var onIMAAdEvent: OnIMAAdEventHandler?
    
    /// Additional query parameters to be included in the ad tag.
    ///
    /// - Example:
    ///   To add consent and non-personalized ads (npa) parameters to your tag:
    ///   ```
    ///   let npaKey = "npa"
    ///   let gdprKey = "gdpr"
    ///   additionalIMATagQueryParams {
    ///     return [npaKey: "0", gdprKey: "0"]
    ///   }
    ///   ```
    public var additionalIMATagQueryParams: AdditionalIMATagQueryParamsHandler?
    
    /// Custom settings for the IMA SDK.
    ///
    /// - Example:
    ///   To set the language and maximum number of redirect URLs:
    ///   ```
    ///   let settings = IMASettings()
    ///   settings.language = "en"
    ///   settings.maxRedirects = 5
    ///   customIMASettings {
    ///      return settings
    ///   }
    ///   ```
    public var customIMASettings: CustomIMASettingsHandler?
    
    public init(onIMAAdError: OnIMAAdErrorHandler? = nil,
                onIMAAdEvent: OnIMAAdEventHandler? = nil,
                additionalIMATagQueryParams: AdditionalIMATagQueryParamsHandler? = nil,
                customIMASettings: CustomIMASettingsHandler? = nil) {
        self.onIMAAdError = onIMAAdError
        self.onIMAAdEvent = onIMAAdEvent
        self.additionalIMATagQueryParams = additionalIMATagQueryParams
        self.customIMASettings = customIMASettings
    }
    
}

//MARK: Intenal default implementations
extension BlazeIMADelegate {
    
    internal var additionalIMATagQueryParamsOrDefault: AdditionalIMATagQueryParamsHandler {
        let defaultImpl: AdditionalIMATagQueryParamsHandler = {
            return [:]
        }
        return additionalIMATagQueryParams ?? defaultImpl
    }
    
    internal var customIMASettingsOrDefault: CustomIMASettingsHandler {
        let defaultImpl: CustomIMASettingsHandler = {
            return nil
        }
        return customIMASettings ?? defaultImpl
    }
}
