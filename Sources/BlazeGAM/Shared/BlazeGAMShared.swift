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
///
/// ## Thread Safety
///
/// All public methods on this class always perform their work on the main thread
/// internally and are asynchronous. They are therefore safe to call from any thread.
///
/// This is required because the underlying Google Mobile Ads SDK uses a `WKWebView`,
/// whose dealloc chain (triggered when a handler is released) must run on the
/// main thread — enforced as a hard assertion on iOS 18+.
///
/// Because the work is dispatched asynchronously, side-effects (e.g.
/// `Blaze.shared.gamBannerAdsHandler` being nil-ed out by `disableBannerAds()`)
/// take effect on the next main-queue tick. Back-to-back calls preserve FIFO order.
public class BlazeGAM {
    
    //MARK: - Public Properties
    
    /// Provides a shared instance of `BlazeGAM` for accessing SDK methods globally.
    public static let shared = BlazeGAM()
    
    //MARK: Public methods
    
    /// Enables custom native advertising functionality within the BlazeSDK.
    /// - Parameters:
    ///   - defaultAdsConfig: An optional `BlazeGAMCustomNativeAdsDefaultConfig` object containing the default configuration settings for ads.
    ///   - delegate: An optional delegate conforming to `BlazeCustomNativeAdsHandler` to handle ad-related callbacks.
    ///
    /// - Note: The work is always performed on the main thread internally and is
    ///   asynchronous. See the class-level *Thread Safety* note.
    public func enableCustomNativeAds(defaultCustomNativeAdsConfig: BlazeGAMCustomNativeAdsDefaultConfig?, delegate: BlazeGAMCustomNativeAdsDelegate?) {
        DispatchQueue.main.async {
            let adsHandler = DefaultBlazeGoogleCustomNativeAdsHandler(defaultAdsConfig: defaultCustomNativeAdsConfig,
                                             delegate: delegate ?? BlazeGAMCustomNativeAdsDelegate())
            Blaze.shared.googleCustomNativeAdsHandler = adsHandler
        }
    }
    
    /// Enables custom native advertising functionality within the BlazeSDK.
    /// - Parameters:
    ///   - defaultAdsConfig: An optional `BlazeGAMDefaultAdsConfig` object containing the default configuration settings for ads.
    ///   - delegate: An optional delegate conforming to `BlazeGAMDelegate` to handle ad-related callbacks.
   @available(*, unavailable, renamed: "enableCustomNativeAds(defaultCustomNativeAdsConfig:delegate:)")
    public func enableCustomNativeAds(defaultAdsConfig: BlazeGAMDefaultAdsConfig?, delegate: BlazeGAMDelegate?) {}
    
    
    /// Disables all custom native ads functionalities by nullifying the ads handler.
    /// This method can be used to turn off custom native ads dynamically in response to user settings or application state changes.
    ///
    /// - Note: The work is always performed on the main thread internally and is
    ///   asynchronous. See the class-level *Thread Safety* note.
    public func disableCustomNativeAds() {
        DispatchQueue.main.async {
            Blaze.shared.googleCustomNativeAdsHandler = nil
        }
    }

    /// Enables Google Ad Manager banner ads within the BlazeSDK.
    /// - Parameter delegate: An optional delegate conforming to `BlazeGAMBannerAdsDelegate` to handle ad-related callbacks.
    ///
    /// - Note: The work is always performed on the main thread internally and is
    ///   asynchronous. See the class-level *Thread Safety* note.
    public func enableBannerAds(delegate: BlazeGAMBannerAdsDelegate?) {
        DispatchQueue.main.async {
            let adsHandler = DefaultBlazeGAMBannerAdsHandler(delegate: delegate ?? BlazeGAMBannerAdsDelegate())
            Blaze.shared.gamBannerAdsHandler = adsHandler
        }
    }
    
    /// Disables Google Ad Manager banner ads by nullifying the banner ads handler.
    ///
    /// - Note: The work is always performed on the main thread internally and is
    ///   asynchronous. See the class-level *Thread Safety* note.
    public func disableBannerAds() {
        DispatchQueue.main.async {
            Blaze.shared.gamBannerAdsHandler = nil
        }
    }

}
