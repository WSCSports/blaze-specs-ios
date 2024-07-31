//
//  BlazeIMAHandler.swift
//
//
//  Created by Dor Zafrir on 09/06/2024.
//

import UIKit
import GoogleInteractiveMediaAds
import BlazeSDK

final class BlazeIMAHandler: NSObject, BlazeIMAHandlerProtocol {

    private var adsLoader: IMAAdsLoader?
    private var adsManager: IMAAdsManager?

    private var volume: Float = 0 {
        didSet {
            adsManager?.volume = volume
        }
    }
    
    //MARK: Delegates
    private class SharedDelegate: BlazeIMAHandlerDelegate {
        
        var appDelegate: BlazeIMADelegate?
        weak var sdkDelegate: BlazeIMAHandlerDelegate?
        
        func onAdError(_ message: String) {
            appDelegate?.onIMAAdError?(message)
            sdkDelegate?.onAdError(message)
        }
        
        func onAdEvent(eventType: BlazeSDK.BlazeIMAHandlerEventType, adInfo: BlazeSDK.BlazeImaAdInfo) {
            appDelegate?.onIMAAdEvent?((eventType: eventType, adInfo: adInfo))
            sdkDelegate?.onAdEvent(eventType: eventType, adInfo: adInfo)
        }
        
        
    }
    
    private let sharedDelegate = SharedDelegate()
    
    // This is the SDK's delegate.
    weak var delegate: BlazeIMAHandlerDelegate? {
        didSet {
            sharedDelegate.sdkDelegate = delegate
        }
    }
    
    // You can set the application's side delegate into this property to receive events too.
    var appDelegate: BlazeIMADelegate? {
        didSet {
            sharedDelegate.appDelegate = appDelegate
        }
    }
    
    override init() {
        super.init()
        setupNotificationObservers()
    }
    
    
    func requestAds(adContainerView: UIView, adVC: UIViewController, adTag: String, initialVolume: Float) {
        // Create ad display container for ad rendering.
        self.volume = initialVolume
        let mergedTagWithExtraParams = merged(tag: adTag, with: adExtraParams())
        adsLoader = nil
        adsManager?.destroy()
        let imaSettings = appDelegate?.customIMASettingsOrDefault()
        adsLoader = IMAAdsLoader(settings: imaSettings)
        adsLoader?.delegate = self
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: adContainerView, viewController: adVC, companionSlots: nil)
        // Create an ad request with our ad tag, display container, and optional user context.
        let request = IMAAdsRequest(
            adTagUrl: mergedTagWithExtraParams,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: nil,
            userContext: nil)

        adsLoader?.requestAds(with: request)
    }

    func updateVolume(to volume: Float) {
        self.volume = volume
    }
    
    private func blazeAdInfo(for ad: IMAAd?) -> BlazeImaAdInfo {
        return BlazeImaAdInfo(adId: ad?.adId, adTitle: ad?.adTitle, adDescription: ad?.adDescription, adSystem: ad?.adSystem, isSkippable: ad?.isSkippable, skipTimeOffset: ad?.skipTimeOffset, adDuration: ad?.duration, advertiserName: ad?.advertiserName)
    }
    
    private func adExtraParams() -> [String: String] {
        return appDelegate?.additionalIMATagQueryParamsOrDefault() ?? [:]
    }
    
    private func merged(tag: String, with extraParams: [String: String]) -> String {
        // Convert the base tag string to URLComponents
        guard var urlComponents = URLComponents(string: tag) else { return tag }
        extraParams.forEach { key, value in
            // Append each extra parameter as a query item
            let queryItem = URLQueryItem(name: key, value: value)
            // If queryItems is nil, initialize it before appending
            if urlComponents.queryItems == nil {
                urlComponents.queryItems = []
            }
            urlComponents.queryItems?.append(queryItem)
        }
        let modifiedTagURL = urlComponents.url
        return modifiedTagURL?.absoluteString ?? tag
    }
}

extension BlazeIMAHandler: IMAAdsLoaderDelegate {

    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        // Initialize the ads manager.
        adsManager?.initialize(with: nil)
        adsManager?.volume = self.volume
    }

    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        let errorMessgae = "BlazeIMAHandler error loading ads: \(adErrorData.adError.message ?? "Unknown")"
        sharedDelegate.onAdError(errorMessgae)
    }
}
    // MARK: - IMAAdsManagerDelegate
extension BlazeIMAHandler: IMAAdsManagerDelegate {

    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        let adInfo = blazeAdInfo(for: event.ad)
        
        switch event.type {
        case .LOADED:
            adsManager.start()
            sharedDelegate.onAdEvent(eventType: .adLoaded, adInfo: adInfo)
        case .ALL_ADS_COMPLETED:
            sharedDelegate.onAdEvent(eventType: .allAdsCompleted, adInfo: adInfo)
            self.adsManager = nil
        case .CLICKED:
            sharedDelegate.onAdEvent(eventType: .adClicked, adInfo: adInfo)
        case .COMPLETE:
            sharedDelegate.onAdEvent(eventType: .adCompleted, adInfo: adInfo)
        case .FIRST_QUARTILE:
            sharedDelegate.onAdEvent(eventType: .adFirstQuartile, adInfo: adInfo)
        case .MIDPOINT:
            sharedDelegate.onAdEvent(eventType: .adMidpoint, adInfo: adInfo)
        case .PAUSE:
            sharedDelegate.onAdEvent(eventType: .adPaused, adInfo: adInfo)
        case .RESUME:
            sharedDelegate.onAdEvent(eventType: .adResumed, adInfo: adInfo)
        case .SKIPPED:
            sharedDelegate.onAdEvent(eventType: .adSkipped, adInfo: adInfo)
        case .STARTED:
            sharedDelegate.onAdEvent(eventType: .adStarted, adInfo: adInfo)
        case .TAPPED:
            sharedDelegate.onAdEvent(eventType: .adTapped, adInfo: adInfo)
        case .THIRD_QUARTILE:
            sharedDelegate.onAdEvent(eventType: .adThirdQuartile, adInfo: adInfo)
        default: break
        }
    }

    func adsManager(_ adsManager: IMAAdsManager, didReceive error: IMAAdError) {
        let errorMessgae = "BlazeIMAHandler error: \(error.message ?? "Unknown")"
        sharedDelegate.onAdError(errorMessgae)
        self.adsManager = nil
    }

    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause any other content.
    }

    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
      // The SDK is done playing ads (at least for now), so resume the content.
    }

}

extension BlazeIMAHandler {
    
    private func setupNotificationObservers() {
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.appDidBecomeActive()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.appWillResignActive()
        }
        
    }
    
    // Handle app did become active
    private func appDidBecomeActive() {
        adsManager?.resume()
    }
    
    // Handle app will move to background
    private func appWillResignActive() {
        adsManager?.pause()
    }
    
}
