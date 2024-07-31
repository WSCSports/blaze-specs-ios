//
//  BlazeAdsHandler.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import BlazeSDK
import GoogleMobileAds

final class BlazeAdsHandler: BlazeGoogleCustomNativeAdsHandler {
    
    let defaultAdsConfig: BlazeGAMDefaultAdsConfig?
    
    var delegate: BlazeGAMDelegate
    
    init(defaultAdsConfig: BlazeGAMDefaultAdsConfig?, delegate: BlazeGAMDelegate) {
        self.defaultAdsConfig = defaultAdsConfig
        self.delegate = delegate
    }
    
    let adsProvider = BlazeAdsProvider()
    
    func onAdEvent(eventType: BlazeGoogleCustomNativeAdsHandlerEventType, adModel: BlazeGoogleCustomNativeAdModel) {
        if let adData = adModel.adData {
            delegate.onGAMAdEvent?((eventType: eventType, adData: adData))
        }
        switch eventType {
        case .openedAd:
            // Report the ad impression to the ad provider.
            adModel.reportAdImpression()

        case .ctaClicked:
            // Report the ad click to the ad provider.
            adModel.reportCTAClicked()

        default:
            break
        }
    }
    
    func provideAd(adRequestData: BlazeAdRequestData) async -> BlazeGoogleCustomNativeAdModel? {
        var ads: BlazeGoogleCustomNativeAdModel?
        do {
            ads = try await adsProvider.generateAd(adRequestData: adRequestData,
                                                   defaultAdsConfig: defaultAdsConfig,
                                                   customTargetingProperties: delegate.customGAMTargetingPropertiesOrDefault())
        } catch {
            delegate.onGAMAdError?(error)
        }
        return ads
    }
    
    
}
