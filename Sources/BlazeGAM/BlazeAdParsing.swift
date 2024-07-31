//
//  BlazeAdParsing.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import GoogleMobileAds
import BlazeSDK

extension GADCustomNativeAd {
    
    func toAdModel() -> BlazeGoogleCustomNativeAdModel? {
        guard let creativeType = string(forKey: BlazeAdsConstants.creativeTypeKey),
              let clickURL = string(forKey: BlazeAdsConstants.clickURLKey),
              let advertiserName = string(forKey: BlazeAdsConstants.advertiserNameKey),
              let trackingURL = string(forKey: BlazeAdsConstants.trackingURLKey),
              let clickType = string(forKey: BlazeAdsConstants.clickTypeKey),
              let clickThroughCTA = string(forKey: BlazeAdsConstants.clickThroughCTAKey) else {
            return nil
        }

        var content: BlazeGoogleCustomNativeAdModel.Content?
        switch creativeType {
        case BlazeAdsConstants.displayType:
            if let imageUrl = image(forKey: BlazeAdsConstants.imageKey)?.imageURL?.absoluteString {
                content = .image(urlString: imageUrl, duration: 5)
            }
            
        case BlazeAdsConstants.videoType:
            if let videoUrl = string(forKey: BlazeAdsConstants.videoKey) {
                let previewImageUrl = string(forKey: BlazeAdsConstants.videoPreviewImageUrlKey)
                content = .video(urlString: videoUrl, loadingImageUrl: previewImageUrl)
            }
            
        default:
            break
        }
        
        // Content must be provided.
        guard let content = content else {
            return nil
        }
        
        var cta: BlazeGoogleCustomNativeAdModel.CtaModel?
        switch clickType {
        case BlazeAdsConstants.webKey:
            cta = .init(type: .web,
                        url: clickURL,
                        text: clickThroughCTA)
        case BlazeAdsConstants.inAppKey:
            cta = .init(type: .deeplink,
                        url: clickURL,
                        text: clickThroughCTA)
        default:
            break
        }
        
        let trackingPixels: Set<BlazeGoogleCustomNativeAdModel.TrackingPixel> = [
            .init(eventType: .openedAd,
                  url: trackingURL)
        ]
        
        let adModel = BlazeGoogleCustomNativeAdModel(content: content,
                              title: advertiserName,
                              cta: cta,
                              trackingPixelAdList: trackingPixels,
                              customAdditionalData: BlazeCustomAdData(nativeAd: self))

        return adModel
    }
    
}
