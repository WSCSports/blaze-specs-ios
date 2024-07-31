//
//  BlazeGAMShared.swift
//
//
//  Created by Dor Zafrir on 18/06/2024.
//

import Foundation
import BlazeSDK

/// The `BlazeGAM` class serves as the central point for managing Google Ad Manager interactions within your application using the Blaze SDK.
/// It provides methods to enable or disable ads dynamically and manages a shared instance for easy access across the application.
public class BlazeGAM {
    
    //MARK: - Public Properties
    
    /// Provides a shared instance of `BlazeGAM` for accessing SDK methods globally.
    public static let shared = BlazeGAM()
    
    //MARK: Public methods
    
    /// Enables custom native advertising functionality within the BlazeSDK.
    /// - Parameters:
    ///   - defaultAdsConfig: An optional `BlazeGAMDefaultAdsConfig` object containing the default configuration settings for ads.
    ///   - delegate: An optional delegate conforming to `BlazeGAMDelegate` to handle ad-related callbacks.
    ///
    /// ---
    ///   - Note: Enabling and disabling ads are not thread-safe. It's your responsibility to make sure you are enabling and disabling ads from the same thread.
    public func enableCustomNativeAds(defaultAdsConfig: BlazeGAMDefaultAdsConfig?, delegate: BlazeGAMDelegate?) {
        let adsHandler = BlazeAdsHandler(defaultAdsConfig: defaultAdsConfig, delegate: delegate ?? BlazeGAMDelegate())
        Blaze.shared.googleCustomNativeAdsHandler = adsHandler
    }
    
    /// Disables all custom native ads functionalities by nullifying the ads handler.
    /// This method can be used to turn off custom native ads dynamically in response to user settings or application state changes.
    /// ---
    ///   - Note: Enabling and disabling ads are not thread-safe. It's your responsibility to make sure you are enabling and disabling ads from the same thread.
    public func disableCustomNativeAds() {
        Blaze.shared.googleCustomNativeAdsHandler = nil
    }

    
 
}
