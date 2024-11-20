//
//  BlazeCustomNativeAdsProvider.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import BlazeSDK
import GoogleMobileAds

final class BlazeCustomNativeAdsProvider {

    func generateAd(adRequestData: BlazeAdRequestData,
                    defaultAdsConfig: BlazeGAMCustomNativeAdsDefaultConfig?,
                    customTargetingProperties: [String: String],
                    publisherProvidedId: String?,
                    networkExtras: GADExtras?) async throws -> BlazeGoogleCustomNativeAdModel? {
        var mergedCustomTargetingProperties = adRequestData.adInfo?.context ?? [:]
        mergedCustomTargetingProperties.merge(customTargetingProperties) { sdk, app in
            // We prefer taking the app's property if we have conflicted properties on both.
            app
        }
        
        let adUnitId = adRequestData.adInfo?.adUnitId ?? defaultAdsConfig?.adUnit ?? ""
        let templateId = adRequestData.adInfo?.formatId ?? defaultAdsConfig?.templateId ?? ""

        let ad = try await BlazeCustomNativeAdsManager.sharedInstance.getNativeAd(adUnitId: adUnitId,
                                                                                  templateId: templateId,
                                                                                  customTargetingProperties: mergedCustomTargetingProperties,
                                                                                  publisherProvidedId: publisherProvidedId,
                                                                                  networkExtras: networkExtras)
        let adModel = ad?.toAdModel()
        if adModel == nil {
            throw BlazeGAMCustomNativeAdsError(reason: .failedParsingAd)
        }
        return adModel
    }

}
