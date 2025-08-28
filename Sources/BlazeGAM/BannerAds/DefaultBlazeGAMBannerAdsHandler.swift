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
        
        let adSize: AdSize
        switch adRequestData.adSize {
        case .banner:
            adSize = AdSizeBanner
        case .largeBanner:
            adSize = AdSizeLargeBanner
        }
        
        let bannerView = AdManagerBannerView(adSize: adSize)
        bannerView.adUnitID = adRequestData.adUnit
        
        callbacks.onAdRequested()
        
        let adData: BlazeGAMBannerAdsAdData = createAdData(from: bannerView,
                                                           extraInfo: adRequestData.extraInfo,
                                                           error: nil)
        delegate.onGAMBannerAdsAdEvent?((eventType: .adRequested, adData: adData))
        
        bannerView.load(AdManagerRequest())
                
        bannerView.blazeAdditionalAdData = .init(
            callbacks: callbacks,
            extraInfo: adRequestData.extraInfo
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

extension DefaultBlazeGAMBannerAdsHandler: BannerViewDelegate {
    
    private func resolveAdData(from bannerView: BannerView, error: Error? = nil) -> BlazeGAMBannerAdsAdData {
        let adData = createAdData(from: bannerView,
                                  extraInfo: bannerView.blazeAdditionalAdData?.extraInfo,
                                  error: error)
        return adData
    }
    
    private func createAdData(
        from bannerView: BannerView,
        extraInfo: BlazeContentExtraInfo?,
        error: Error?
    ) -> BlazeGAMBannerAdsAdData {
        let extraInfo = extraInfo ?? .init(previous: nil, current: nil, next: nil)
        let adData = BlazeGAMBannerAdsAdData(bannerView: bannerView, extraInfo: (error == nil) ? extraInfo : .init())
        return adData
    }
    
    func bannerViewDidReceiveAd(_ bannerView: BannerView) {
        
        let adData = resolveAdData(from: bannerView)

        delegate.onGAMBannerAdsAdEvent?((eventType: .adLoaded, adData: adData))
        
        // Report ad loaded to the sdk.
        bannerView.blazeAdditionalAdData?.callbacks.onAdLoaded()
        
        bannerView.animateEntrance()
    }
    
    func bannerViewDidRecordClick(_ bannerView: BannerView) {
        
        let adData = resolveAdData(from: bannerView)

        delegate.onGAMBannerAdsAdEvent?((eventType: .adClicked, adData: adData))
        
        // Report impression to the sdk.
        bannerView.blazeAdditionalAdData?.callbacks.onAdClick()
    }
    
    func bannerViewDidRecordImpression(_ bannerView: BannerView) {
        
        let adData = resolveAdData(from: bannerView)

        delegate.onGAMBannerAdsAdEvent?((eventType: .adImpression, adData: adData))
        
        // Report impression to the sdk.
        bannerView.blazeAdditionalAdData?.callbacks.onAdImpression()
    }
    
    func bannerView(_ bannerView: BannerView, 
                    didFailToReceiveAdWithError error: any Error) {
        
        let adData = resolveAdData(from: bannerView, error: error)
        delegate.onGAMBannerAdsAdError?((error: error, adData: adData))
    }
}

internal extension BannerView {
    struct BlazeAdditionalAdData {
        let callbacks: BlazeGAMBannerAdsHandlerCallbacks
        let extraInfo: BlazeContentExtraInfo
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
