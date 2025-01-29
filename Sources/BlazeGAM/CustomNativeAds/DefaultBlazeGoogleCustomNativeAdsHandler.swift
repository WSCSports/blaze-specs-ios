//
//  DefaultBlazeGoogleCustomNativeAdsHandler.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import BlazeSDK
import GoogleMobileAds

final class DefaultBlazeGoogleCustomNativeAdsHandler: BlazeGoogleCustomNativeAdsHandler {
    
    let defaultAdsConfig: BlazeGAMCustomNativeAdsDefaultConfig?
    
    var delegate: BlazeGAMCustomNativeAdsDelegate
    
    init(defaultAdsConfig: BlazeGAMCustomNativeAdsDefaultConfig?, delegate: BlazeGAMCustomNativeAdsDelegate) {
        self.defaultAdsConfig = defaultAdsConfig
        self.delegate = delegate
    }
    
    let adsProvider = BlazeCustomNativeAdsProvider()
    
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
            let adUnitId = adRequestData.adInfo?.adUnitId ?? defaultAdsConfig?.adUnit ?? ""
            let templateId = adRequestData.adInfo?.formatId ?? defaultAdsConfig?.templateId ?? ""
            let adContext = adRequestData.adInfo?.context ?? [:]
            
            let requestData: BlazeGamCustomNativeAdRequestInformation = .init(adUnitId: adUnitId,
                                                                    templateId: templateId,
                                                                    adContext: adContext)
            
            ads = try await adsProvider.generateAd(adUnitId: adUnitId,
                                                   templateId: templateId,
                                                   adContext: adContext,
                                                   customTargetingProperties: delegate.customGAMTargetingPropertiesOrDefault(.init(requestDataInfo: requestData)),
                                                   publisherProvidedId: delegate.publisherProvidedId?(.init(requestDataInfo: requestData)),
                                                   networkExtras: delegate.networkExtras?(.init(requestDataInfo: requestData)))
        } catch {
            delegate.onGAMAdError?(error)
        }
        return ads
    }
    
    
}
