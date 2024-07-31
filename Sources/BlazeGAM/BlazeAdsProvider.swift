//
//  BlazeAdsProvider.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import BlazeSDK

final class BlazeAdsProvider {

    func generateAd(adRequestData: BlazeAdRequestData,
                    defaultAdsConfig: BlazeGAMDefaultAdsConfig?,
                    customTargetingProperties: [String: String]) async throws -> BlazeGoogleCustomNativeAdModel? {
        var mergedCustomTargetingProperties = adRequestData.adInfo?.context ?? [:]
        mergedCustomTargetingProperties.merge(customTargetingProperties) { sdk, app in
            // We prefer taking the app's property if we have conflicted properties on both.
            app
        }
        
        let adUnitId = adRequestData.adInfo?.adUnitId ?? defaultAdsConfig?.adUnit ?? ""
        let templateId = adRequestData.adInfo?.formatId ?? defaultAdsConfig?.templateId ?? ""

        let ad = try await BlazeAdManager.sharedInstance.getNativeAd(adUnitId: adUnitId,
                                                                     templateId: templateId,
                                                                     customTargetingProperties: mergedCustomTargetingProperties)
        let adModel = ad?.toAdModel()
        if adModel == nil {
            throw BlazeGAMError(reason: .failedParsingAd)
        }
        return adModel
    }

}
