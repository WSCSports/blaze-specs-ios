//
//  BlazeAdsReporting.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import GoogleMobileAds
import BlazeSDK

extension BlazeGoogleCustomNativeAdModel {
    
    func reportAdImpression() {
        nativeAd?.recordImpression()
    }
    
    func reportCTAClicked() {
        let assetKey: String
        switch content {
        case .image:
            assetKey = BlazeAdsConstants.imageKey
        case .video:
            assetKey = BlazeAdsConstants.videoKey
        }

        nativeAd?.customClickHandler = { _ in }
        nativeAd?.performClickOnAsset(withKey: assetKey)
    }

    
    var nativeAd: GADCustomNativeAd? {
       adData?.nativeAd
    }
    
    var adData: BlazeCustomAdData? {
        customAdditionalData as? BlazeCustomAdData
    }
}
