//
//  BlazeAdManager.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import GoogleMobileAds
import UIKit

final class BlazeAdManager: NSObject, GADAdLoaderDelegate, GADCustomNativeAdLoaderDelegate {
    
    static let sharedInstance = BlazeAdManager()
    
    private var currentAdRequests = [BlazeNativeAdRequest]()
    
    /// Load a single ad from Google and wait for it's result to return.
    ///
    /// - Parameters:
    ///   - adUnitId: adUnit to load.
    ///   - templateId: templateId.
    ///   - customTargetingProperties: customTargetingProperties
    /// - Returns: the loaded ad, or nil if any error occured.
    func getNativeAd(adUnitId: String,
                     templateId: String,
                     customTargetingProperties: [String: String]) async throws -> GADCustomNativeAd? {
        return try await withCheckedThrowingContinuation { continuation in
            BlazeAdManager.sharedInstance.getNativeAd(
                adUnitId: adUnitId,
                templateId: templateId,
                customTargetingProperties: customTargetingProperties) { ad, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else if let nativeAd = ad {
                        continuation.resume(returning: nativeAd)
                    } else {
                        continuation.resume(throwing: BlazeGAMError(reason: .noAdFoundWithUnknownError))
                    }
                }
        }
    }
    
    private func getNativeAd(adUnitId: String,
                             templateId: String,
                             customTargetingProperties: [String: String],
                             completion: @escaping (GADCustomNativeAd?, Error?) -> Void) {
        let adLoader = GADAdLoader(
            adUnitID: adUnitId,
            rootViewController: nil,
            adTypes: [GADAdLoaderAdType.customNative],
            options: nil)
        adLoader.delegate = self
        
        let request = GAMRequest()
        request.customTargeting = customTargetingProperties
        
        
        let nativeAdRequest = BlazeNativeAdRequest(adLoader: adLoader,
                                                   completion: completion,
                                                   templateId: templateId)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.currentAdRequests.append(nativeAdRequest)
            adLoader.load(request)
        }
    }
    
    func customNativeAdFormatIDs(for adLoader: GADAdLoader) -> [String] {
        let templateId = currentAdRequests.first { nativeAdRequest in
            nativeAdRequest.adLoader == adLoader
        }?.templateId ?? ""
        
        return [templateId]
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive customNativeAd: GADCustomNativeAd) {
        guard let nativeAdRequest = currentAdRequests.first(where: { nativeAdRequest in
            nativeAdRequest.adLoader == adLoader
        }) else { return }
        nativeAdRequest.completion(customNativeAd, nil)
        removeAdRequest(adRequest: nativeAdRequest)
    }
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        guard let nativeAdRequest = currentAdRequests.first(where: { nativeAdRequest in
            nativeAdRequest.adLoader == adLoader
        }) else { return }
        nativeAdRequest.completion(nil, error)
        removeAdRequest(adRequest: nativeAdRequest)
    }
    
    private func removeAdRequest(adRequest: BlazeNativeAdRequest) {
        currentAdRequests.removeAll(where: { $0 == adRequest })
    }
}
