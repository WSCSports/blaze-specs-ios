//
//  BlazeGAMCustomNativeAdsDefaultConfig.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation

/// `BlazeGAMCustomNativeAdsDefaultConfig` is a structure designed to store the basic configuration needed for requesting ads within the BlazeGAM system.
public struct BlazeGAMCustomNativeAdsDefaultConfig: Codable {
        
    /// The ad unit ID as a string. This identifier is used by the ad serving system to fetch the appropriate ad content.
    /// It is crucial for targeting and delivering ads that are specific to different parts of an application or different audience segments.
    public let adUnit: String
    
    /// The template ID for the ad. This string identifies the template to be used when rendering the ad.
    /// Templates determine the layout and visual presentation of ads, allowing for consistent styling and formatting across different ads.
    public let templateId: String
    
    /// Initializes a new instance of `BlazeGAMCustomNativeAdsDefaultConfig`
    /// This initializer sets up the default configuration with all necessary details required to request and render ads based on provided parameters.
    ///
    /// - Parameters:
    ///   - adUnit: The unique identifier for the ad unit. This is used to specify which ad unit's settings to apply when fetching ads.
    ///   - templateId: The identifier for the template to use when rendering ads. This controls the visual layout and style of the ads.
    public init(adUnit: String, templateId: String) {
        self.adUnit = adUnit
        self.templateId = templateId
    }
    
}

/// `BlazeGAMDefaultAdsConfig` is a structure designed to store the basic configuration needed for requesting ads within the BlazeGAM system.
@available(*, unavailable, renamed: "BlazeGAMCustomNativeAdsDefaultConfig")
public struct BlazeGAMDefaultAdsConfig: Codable {
        
    /// The ad unit ID as a string. This identifier is used by the ad serving system to fetch the appropriate ad content.
    /// It is crucial for targeting and delivering ads that are specific to different parts of an application or different audience segments.
    public let adUnit: String
    
    /// The template ID for the ad. This string identifies the template to be used when rendering the ad.
    /// Templates determine the layout and visual presentation of ads, allowing for consistent styling and formatting across different ads.
    public let templateId: String
    
    /// Initializes a new instance of `BlazeGAMDefaultAdsConfig`
    /// This initializer sets up the default configuration with all necessary details required to request and render ads based on provided parameters.
    ///
    /// - Parameters:
    ///   - adUnit: The unique identifier for the ad unit. This is used to specify which ad unit's settings to apply when fetching ads.
    ///   - templateId: The identifier for the template to use when rendering ads. This controls the visual layout and style of the ads.
    public init(adUnit: String, templateId: String) {
        self.adUnit = adUnit
        self.templateId = templateId
    }
    
}
