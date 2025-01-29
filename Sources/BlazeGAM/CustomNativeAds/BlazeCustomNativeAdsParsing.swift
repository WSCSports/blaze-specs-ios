//
//  BlazeCustomNativeAdsParsing.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import GoogleMobileAds
import BlazeSDK

internal extension GADCustomNativeAd {
    
    func toAdModel() -> BlazeGoogleCustomNativeAdModel? {
        guard let creativeType = string(forKey: BlazeCustomNativeAdsConstants.creativeTypeKey),
              let clickURL = string(forKey: BlazeCustomNativeAdsConstants.clickURLKey),
              let advertiserName = string(forKey: BlazeCustomNativeAdsConstants.advertiserNameKey),
              let clickType = string(forKey: BlazeCustomNativeAdsConstants.clickTypeKey),
              let clickThroughCTA = string(forKey: BlazeCustomNativeAdsConstants.clickThroughCTAKey) else {
            return nil
        }
        
        var impressionPixelsURLs: [String] = []
        if let trackingURL = string(forKey: BlazeCustomNativeAdsConstants.trackingURLKey) {
            impressionPixelsURLs.append(trackingURL)
        }
        if let impressionTrackingURLs = string(forKey: BlazeCustomNativeAdsConstants.impressionTrackingUrlsKey) {
            let urlsArr = impressionTrackingURLs.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            impressionPixelsURLs.append(contentsOf: urlsArr)
        }
        
        var clickPixelsURLs: [String] = []
        if let clickTrackingURLs = string(forKey: BlazeCustomNativeAdsConstants.clickTrackingUrlsKey) {
            let urlsArr = clickTrackingURLs.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            clickPixelsURLs.append(contentsOf: urlsArr)
        }

        var content: BlazeGoogleCustomNativeAdModel.Content?
        switch creativeType {
        case BlazeCustomNativeAdsConstants.displayType:
            if let imageUrl = image(forKey: BlazeCustomNativeAdsConstants.imageKey)?.imageURL?.absoluteString {
                content = .image(urlString: imageUrl, duration: 5)
            }
            
        case BlazeCustomNativeAdsConstants.videoType:
            if let videoUrl = string(forKey: BlazeCustomNativeAdsConstants.videoKey) {
                let previewImageUrl = string(forKey: BlazeCustomNativeAdsConstants.videoPreviewImageUrlKey)
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
        case BlazeCustomNativeAdsConstants.webKey:
            cta = .init(type: .web,
                        url: clickURL,
                        text: clickThroughCTA)
        case BlazeCustomNativeAdsConstants.inAppKey:
            cta = .init(type: .deeplink,
                        url: clickURL,
                        text: clickThroughCTA)
        default:
            break
        }
        
        let trackingPixels: Set<BlazeGoogleCustomNativeAdModel.TrackingPixel> = [
            .init(eventType: .openedAd,
                  urls: impressionPixelsURLs),
            .init(eventType: .ctaClicked,
                  urls: clickPixelsURLs)
        ]
        
        let adModel = BlazeGoogleCustomNativeAdModel(content: content,
                              title: advertiserName,
                              cta: cta,
                              trackingPixelAdList: trackingPixels,
                              customAdditionalData: BlazeCustomNativeAdData(nativeAd: self))

        return adModel
    }
    
}
