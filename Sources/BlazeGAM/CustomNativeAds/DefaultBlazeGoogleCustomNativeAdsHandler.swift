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
            
            let requestData: BlazeGamCustomNativeAdRequestInformation =
                .init(adUnitId: adUnitId,
                      templateId: templateId,
                      adContext: adContext,
                      extraInfo: adRequestData.extraInfo ?? .init()
                )
            
            let delegateResults = await loadDelegateResults(requestData: requestData)
            
            ads = try await adsProvider.generateAd(adUnitId: adUnitId,
                                                   templateId: templateId,
                                                   adContext: adContext,
                                                   extraInfo: adRequestData.extraInfo ?? .init(),
                                                   customTargetingProperties: delegateResults.customGAMTargetingProperties,
                                                   publisherProvidedId: delegateResults.publisherProvidedId,
                                                   networkExtras: delegateResults.networkExtras)
        } catch {
            delegate.onGAMAdError?(error)
        }
        return ads
    }
    
    /// Run delegate calls in parallel on background threads (explicitly off main thread by design)
    /// If we do want to change this to run on the main thread, we can change the delegate declaration and add @MainActor, for example from:
    /// ```swift
    /// public typealias CustomGAMTargetingPropertiesHandler = (_ params: RequestDataInfo) async -> [String : String]
    /// ```
    /// to
    /// ```swift
    /// public typealias CustomGAMTargetingPropertiesHandler = @MainActor (_ params: RequestDataInfo) async -> [String : String]
    /// ```
    ///
    func loadDelegateResults(requestData: BlazeGamCustomNativeAdRequestInformation) async -> DelegateResults {
        async let customGAMTargetingPropertiesAsync = delegate.customGAMTargetingProperties?(.init(requestDataInfo: requestData))
        async let publisherProvidedIdAsync = delegate.publisherProvidedId?(.init(requestDataInfo: requestData))
        async let networkExtrasAsync = delegate.networkExtras?(.init(requestDataInfo: requestData))
        
        // Await all results (still on main thread)
        let customGAMTargetingProperties = await customGAMTargetingPropertiesAsync ?? [:]
        let publisherProvidedId = await publisherProvidedIdAsync
        let networkExtras = await networkExtrasAsync
        
        return .init(customGAMTargetingProperties: customGAMTargetingProperties,
                     publisherProvidedId: publisherProvidedId,
                     networkExtras: networkExtras)
    }
    
    struct DelegateResults {
        let customGAMTargetingProperties: [String: String]
        let publisherProvidedId: String?
        let networkExtras: Extras?
    }
    
}
