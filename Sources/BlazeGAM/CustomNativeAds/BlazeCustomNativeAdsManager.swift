//
//  BlazeCustomNativeAdsManager.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import GoogleMobileAds
import UIKit

final class BlazeCustomNativeAdsManager: NSObject, AdLoaderDelegate, CustomNativeAdLoaderDelegate {
    
    static let sharedInstance = BlazeCustomNativeAdsManager()
    
    private var currentAdRequests = [BlazeCustomNativeAdRequest]()
    
    /// Load a single ad from Google and wait for it's result to return.
    ///
    /// - Parameters:
    ///   - adUnitId: adUnit to load.
    ///   - templateId: templateId.
    ///   - customTargetingProperties: customTargetingProperties
    /// - Returns: the loaded ad, or nil if any error occured.
    func getNativeAd(adUnitId: String,
                     templateId: String,
                     customTargetingProperties: [String: String],
                     publisherProvidedId: String?,
                     networkExtras: Extras?) async throws -> CustomNativeAd? {
        return try await withCheckedThrowingContinuation { continuation in
            BlazeCustomNativeAdsManager.sharedInstance.getNativeAd(
                adUnitId: adUnitId,
                templateId: templateId,
                customTargetingProperties: customTargetingProperties,
                publisherProvidedId: publisherProvidedId,
                networkExtras: networkExtras) { ad, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let nativeAd = ad {
                        continuation.resume(returning: nativeAd)
                    } else {
                        continuation.resume(throwing: BlazeGAMCustomNativeAdsError(reason: .noAdFoundWithUnknownError))
                    }
                }
        }
    }
    
    private func getNativeAd(adUnitId: String,
                             templateId: String,
                             customTargetingProperties: [String: String],
                             publisherProvidedId: String?,
                             networkExtras: Extras?,
                             completion: @escaping (CustomNativeAd?, Error?) -> Void) {
        let adLoader = AdLoader(
            adUnitID: adUnitId,
            rootViewController: nil,
            adTypes: [AdLoaderAdType.customNative],
            options: nil)
        adLoader.delegate = self
        
        let request = AdManagerRequest()
        request.customTargeting = customTargetingProperties
        
        // Add publisher provided ID if it is set
        if let publisherId = publisherProvidedId {
            request.publisherProvidedID = publisherId
        }

        // Add network extras bundle if it is set
        if let extras = networkExtras {
            request.register(extras)
        }
        
        
        let nativeAdRequest = BlazeCustomNativeAdRequest(adLoader: adLoader,
                                                   completion: completion,
                                                   templateId: templateId)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentAdRequests.append(nativeAdRequest)
            adLoader.load(request)
        }
    }
    
    func customNativeAdFormatIDs(for adLoader: AdLoader) -> [String] {
        let templateId = currentAdRequests.first { nativeAdRequest in
            nativeAdRequest.adLoader == adLoader
        }?.templateId ?? ""
        
        return [templateId]
    }
    
    func adLoader(_ adLoader: AdLoader, didReceive customNativeAd: CustomNativeAd) {
        guard let nativeAdRequest = currentAdRequests.first(where: { nativeAdRequest in
            nativeAdRequest.adLoader == adLoader
        }) else { return }
        nativeAdRequest.completion(customNativeAd, nil)
        removeAdRequest(adRequest: nativeAdRequest)
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        guard let nativeAdRequest = currentAdRequests.first(where: { nativeAdRequest in
            nativeAdRequest.adLoader == adLoader
        }) else { return }
        nativeAdRequest.completion(nil, error)
        removeAdRequest(adRequest: nativeAdRequest)
    }
    
    private func removeAdRequest(adRequest: BlazeCustomNativeAdRequest) {
        currentAdRequests.removeAll(where: { $0 == adRequest })
    }
}
