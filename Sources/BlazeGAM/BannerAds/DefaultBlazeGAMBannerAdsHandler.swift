//
//  DefaultBlazeGAMBannerAdsHandler.swift
//
//
//  Created by Reuven Levitsky on 08/08/2024.
//

import Foundation
import BlazeSDK
import GoogleMobileAds

final class DefaultBlazeGAMBannerAdsHandler: NSObject, BlazeGAMBannerAdsHandler {
    
    var delegate: BlazeGAMBannerAdsDelegate
    
    init(delegate: BlazeGAMBannerAdsDelegate) {
        self.delegate = delegate
    }
    
    let adsProvider = BlazeCustomNativeAdsProvider()
    
    func createBannerView(adRequestData: BlazeGAMBannerAdsRequestData,
                          callbacks: BlazeGAMBannerAdsHandlerCallbacks) -> UIView? {
        
        let adSize: GADAdSize
        switch adRequestData.adSize {
        case .banner:
            adSize = GADAdSizeBanner
        case .largeBanner:
            adSize = GADAdSizeLargeBanner
        }
        
        let bannerView = GAMBannerView(adSize: adSize)
        bannerView.adUnitID = adRequestData.adUnit
        
        bannerView.load(GAMRequest())
        
        bannerView.blazeAdditionalAdData = .init(
            callbacks: callbacks
        )
        
        bannerView.delegate = self
        
        // Set it's size.
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.widthAnchor.constraint(equalToConstant: adSize.size.width),
            bannerView.heightAnchor.constraint(equalToConstant: adSize.size.height),
        ])
        
        return bannerView
    }
    
}

extension DefaultBlazeGAMBannerAdsHandler: GADBannerViewDelegate {
    
    func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
        delegate.onGAMBannerAdsAdEvent?((eventType: .adLoaded,
                                         adData: .init(bannerView: bannerView)))
        
        // Report ad loaded to the sdk.
        bannerView.blazeAdditionalAdData?.callbacks.onAdLoaded()
        
        bannerView.animateEntrance()
    }
    
    func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
        delegate.onGAMBannerAdsAdEvent?((eventType: .adClicked,
                                         adData: .init(bannerView: bannerView)))
        
        // Report impression to the sdk.
        bannerView.blazeAdditionalAdData?.callbacks.onAdClick()
    }
    
    func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
        delegate.onGAMBannerAdsAdEvent?((eventType: .adImpression,
                                         adData: .init(bannerView: bannerView)))
        
        // Report impression to the sdk.
        bannerView.blazeAdditionalAdData?.callbacks.onAdImpression()
    }
    
    func bannerView(_ bannerView: GADBannerView, 
                    didFailToReceiveAdWithError error: any Error) {
        delegate.onGAMBannerAdsAdError?((error: error,
                                         adData: .init(bannerView: bannerView)))
    }
    
}

internal extension GADBannerView {
    struct BlazeAdditionalAdData {
        
        let callbacks: BlazeGAMBannerAdsHandlerCallbacks
        
    }
    
    private struct AssociatedKeys {
        static var blazeAdditionalAdData: Void?
    }

    var blazeAdditionalAdData: BlazeAdditionalAdData? {
        get {
            return objc_getAssociatedObject(self, 
                                            &AssociatedKeys.blazeAdditionalAdData) as? BlazeAdditionalAdData
        }
        set {
            objc_setAssociatedObject(self, 
                                     &AssociatedKeys.blazeAdditionalAdData,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func animateEntrance() {
        alpha = 0
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.alpha = 1
        }
    }
}
