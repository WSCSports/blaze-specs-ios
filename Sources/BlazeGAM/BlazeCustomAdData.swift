//
//  BlazeCustomAdData.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import GoogleMobileAds

/// `BlazeCustomAdData` is a structure that encapsulates data related to a native advertisement.
/// It serves as a container for ad information that can be used throughout the `BlazeGAM` system
/// to manage and display native ads effectively.
public struct BlazeCustomAdData {
    
    /// An optional instance of `GADCustomNativeAd` from Google Ad Manager SDK.
    /// This property may contain a native ad object when an ad is successfully loaded, allowing
    /// access to its details and functionalities such as assets, tracking, and interaction handlers.
    /// If no ad is loaded, this property is nil, indicating that the ad data is not available.
    public let nativeAd: GADCustomNativeAd?
}
