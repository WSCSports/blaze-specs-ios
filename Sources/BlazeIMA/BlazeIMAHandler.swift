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

    /// Single `IMAAdsLoader` reused for the entire lifetime of the handler, as recommended by
    /// Google IMA. Subsequent requests reuse it; dedup between sequential requests on the same
    /// tag is reset via `adsManager.destroy()` + `loader.contentComplete()` (see `resetLoaderDedupIfIdle`).
    /// Concurrent requests (live + background prefetch) are distinguished by the request `userContext`.
    private var sharedAdsLoader: IMAAdsLoader?

    /// Set when a manager finishes or is destroyed; the next request must call `contentComplete()`
    /// on the shared loader (while idle) so it is not flagged as a duplicate of the prior request.
    private var loaderNeedsContentComplete = false
    private var adsManager: IMAAdsManager?
    private let adTagEnricher = BlazeIMAAdTagEnricher()
    private var mergedOrOverriddenAdTagUrl: String?
    private var currentContentExtraInfo: BlazeContentExtraInfo?

    // MARK: Prefetch state
    /// All prefetch bookkeeping (sessions, cancellation tombstones, session cap) lives in the
    /// store, which exposes only atomic compound operations — see `BlazeIMAPrefetchSessionStore`.
    /// The cap is a safety net only — the service enforces the real budget. The `+ 1` is
    /// headroom for the one presenting session, which lingers here (exempt from the service
    /// budget) while the next slot already warms; without it the cap would fire on normal
    /// show transitions.
    ///
    /// Relies on at most one presentation at a time: ads are fullscreen-modal, so while one
    /// player shows an ad the other is covered and can't reach its own show, and the Videos
    /// player uses the live path (no presenting entry). If that ever breaks, the fallout is a
    /// declined warm slot → live fallback on show, plus possibly wrong `adTag`/`extraInfo` on a
    /// concurrent live ad's events (`notifyFailedPrefetchReached` repoints the shared analytics
    /// fields outside any presentation) — never a crash.
    private let prefetchStore = BlazeIMAPrefetchSessionStore(
        maxSessions: BlazeIMAPrefetchBudget.maxWarmedTotal + 1
    )
    /// Strong reference to the display container of the currently shown prefetched ad.
    /// Kept until ALL_ADS_COMPLETED because its `adContainerViewController` is weak and the
    /// container would otherwise be released while the ad is still rendering.
    private var activeDisplayContainer: IMAAdDisplayContainer?

    /// Test hook: unit-test hosts have no key window, which would abort `prefetchAds` early.
    var windowOverrideForTesting: UIWindow?

    var volume: Float = 0 {
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

        /// Client delegate only — bypasses the shared `sdkDelegate`, which may point at another
        /// player. For a failed prefetch slot; the owning player drives its own resume.
        func onAppDelegateAdEvent(eventType: BlazeSDK.BlazeIMAHandlerEventType, adInfo: BlazeSDK.BlazeImaAdInfo) {
            appDelegate?.onIMAAdEvent?((eventType: eventType, adInfo: adInfo))
        }

        func onAppDelegateAdError(_ message: String) {
            appDelegate?.onIMAAdError?(message)
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
    
    @MainActor
    func requestAds(adContainerView: UIView,
                    adVC: UIViewController,
                    requestData: BlazeIMAAdRequestData,
                    initialVolume: Float) async {
        if adsManager != nil {
            adsManager?.destroy()
            adsManager = nil
            loaderNeedsContentComplete = true
        }
        mergedOrOverriddenAdTagUrl = nil
        currentContentExtraInfo = requestData.extraInfo
        
        // Create ad display container for ad rendering.
        self.volume = initialVolume
        
        // This information will be passed to the app through ima delegate for any custom logic
        let requestExtraInformation: BlazeIMAAdRequestInformation = .init(
            contentExtraInfo: requestData.contentExtraInfo,
            extraInfo: requestData.extraInfo
        )
        
        let delegateResults = await loadDelegateResults(requestData: .init(requestDataInfo: requestExtraInformation))
        
        // Determine the final ad tag URL using the override if provided, or fall back to the enriched URL.
        // The override is used verbatim, deliberately not sanitized - the client owns that string.
        let mergedOrOverriddenAdTagUrl = delegateResults.overriddenAdTagUrl ?? adTagEnricher.enrichedTagURL(
            requestData: requestData,
            appExtraParams: delegateResults.appExtraParams,
            initialVolume: initialVolume
        )
        
        self.mergedOrOverriddenAdTagUrl = mergedOrOverriddenAdTagUrl

        // A malformed tag would only fail the network request after the usual delay, holding
        // the loading spinner for nothing — fail fast instead. `.adRequested` still fires first
        // so pause/resume of the original player stays symmetric with the normal error path.
        guard mergedOrOverriddenAdTagUrl.isValidAdTagURL else {
            sharedDelegate.onAdEvent(eventType: .adRequested, adInfo: blazeAdInfo(for: nil))
            sharedDelegate.onAdError("BlazeIMAHandler error loading ads: invalid ad tag URL")
            return
        }
        
        let adDisplayContainer = IMAAdDisplayContainer(adContainer: adContainerView,
                                                       viewController: adVC,
                                                       companionSlots: nil)

        resetLoaderDedupIfIdle()
        let loader = obtainSharedLoader(settings: delegateResults.imaSettings)

        // Create an ad request with our ad tag, display container, and optional user context.
        sharedDelegate.onAdEvent(eventType: .adRequested, adInfo: blazeAdInfo(for: nil))
        let request = IMAAdsRequest(
            adTagUrl: mergedOrOverriddenAdTagUrl,
            adDisplayContainer: adDisplayContainer,
            contentPlayhead: nil,
            userContext: nil)

        loader.requestAds(with: request)
    }

    func updateVolume(to volume: Float) {
        self.volume = volume
    }
    
    private func blazeAdInfo(for ad: IMAAd?) -> BlazeImaAdInfo {
        return BlazeImaAdInfo(
            adId: ad?.adId,
            adTitle: ad?.adTitle,
            adDescription: ad?.adDescription,
            adSystem: ad?.adSystem,
            isSkippable: ad?.isSkippable,
            skipTimeOffset: ad?.skipTimeOffset,
            adDuration: ad?.duration,
            advertiserName: ad?.advertiserName,
            adTag: mergedOrOverriddenAdTagUrl,
            extraInfo: currentContentExtraInfo
        )
    }
    
    private func extraParamsFromApp(_ requestData: BlazeIMADelegate.RequestDataInfo) async -> [String: String] {
        return await appDelegate?.additionalIMATagQueryParamsOrDefault(requestData) ?? [:]
    }

    // MARK: - Shared loader

    /// Returns the shared loader, lazily creating it on first use. The `settings` are applied only
    /// at creation time; they are effectively static per session, so later values are ignored.
    @MainActor
    private func obtainSharedLoader(settings: IMASettings?) -> IMAAdsLoader {
        if let loader = sharedAdsLoader { return loader }
        let loader = IMAAdsLoader(settings: settings)
        loader.delegate = self
        sharedAdsLoader = loader
        return loader
    }

    /// Resets the loader's duplicate-request state for the next request, but only while the loader
    /// is idle. Calling `contentComplete()` is unsafe while a live manager is active or a prefetch
    /// session is still in-flight/held; in those cases the request is concurrent (distinct
    /// `userContext`) and is not treated as a duplicate, so the reset can be safely skipped.
    ///
    /// Why this dance exists (do NOT "simplify" to a fresh IMAAdsLoader per request): Google IMA
    /// requires reusing one loader — reuse reduces latency and is what makes frequency capping work;
    /// a new loader per request breaks capping. The price of reuse is that re-requesting the same tag
    /// must be preceded by `adsManager.destroy()` → `loader.contentComplete()`, or the repeat request
    /// is treated as an accidental duplicate and returns no ads. `contentComplete()` also fires any
    /// pending post-rolls, hence the idle-only guard. Refs: IMA iOS FAQ + "Reducing latency".
    @MainActor
    private func resetLoaderDedupIfIdle() {
        guard loaderNeedsContentComplete, adsManager == nil, !prefetchStore.hasActiveSessions() else { return }
        sharedAdsLoader?.contentComplete()
        loaderNeedsContentComplete = false
    }
    
    /// Run delegate calls in parallel on background threads (explicitly off main thread by design)
    /// If we do want to change this to run on the main thread, we can change the delegate declaration and add @MainActor, for example from:
    /// ```swift
    /// public typealias CustomGAMTargetingPropertiesHandler = (_ params: RequestDataInfo) async -> [String : String]
    /// ```
    /// to
    /// ```swift
    /// public typealias CustomGAMTargetingPropertiesHandler = @MainActor (_ params: RequestDataInfo) async -> [String : String]
    /// ```
    ///
    func loadDelegateResults(requestData: BlazeIMADelegate.RequestDataInfo) async -> DelegateResults {
        // Run delegate calls in parallel on background threads (explicitly off main thread by design)
        async let appExtraParamsAsync = extraParamsFromApp(requestData)
        async let overriddenAdTagUrlAsync = appDelegate?.overrideAdTagUrl?(requestData)
        async let imaSettingsAsync = appDelegate?.customIMASettingsOrDefault(requestData)
        
        // Run delegate calls in parallel on background threads (explicitly off main thread by design)
        // If we do want to change this to run on the main thread, we can change the delegate declaration and add @MainActor, for example from:
        /// ```swift
        /// public typealias CustomGAMTargetingPropertiesHandler = (_ params: RequestDataInfo) async -> [String : String]
        /// ```
        /// to
        /// ```swift
        /// public typealias CustomGAMTargetingPropertiesHandler = @MainActor (_ params: RequestDataInfo) async -> [String : String]
        /// ```
        ///
        let appExtraParams = await appExtraParamsAsync
        let overriddenAdTagUrl = await overriddenAdTagUrlAsync
        let imaSettings = await imaSettingsAsync
        
        return .init(appExtraParams: appExtraParams,
                     overriddenAdTagUrl: overriddenAdTagUrl,
                     imaSettings: imaSettings)
    }
    
    struct DelegateResults {
        let appExtraParams: [String: String]
        let overriddenAdTagUrl: String?
        let imaSettings: IMASettings?
    }
    
}

// MARK: - IMAAdsLoaderDelegate
extension BlazeIMAHandler: IMAAdsLoaderDelegate {

    func adsLoader(_ loader: IMAAdsLoader, adsLoadedWith adsLoadedData: IMAAdsLoadedData) {
        // IMA does not contractually guarantee delegate callbacks on the main thread, so marshal
        // onto main before touching main-confined live state. Synchronous no-op on the normal path.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.adsLoader(loader, adsLoadedWith: adsLoadedData) }
            return
        }
        if let token = adsLoadedData.userContext as? String {
            // Late response for a cancelled prefetch — drop it so it doesn't fall into the
            // live flow below (see `BlazeIMAPrefetchSessionStore`'s tombstones).
            if prefetchStore.consumeTombstone(token) {
                adsLoadedData.adsManager?.destroy()
                loaderNeedsContentComplete = true
                return
            }
            if prefetchStore.hasSession(token) {
                handlePrefetchAdsLoaded(token: token, adsManager: adsLoadedData.adsManager)
                return
            }
        }

        adsManager = adsLoadedData.adsManager
        adsManager?.delegate = self
        // Initialize the ads manager.
        adsManager?.initialize(with: nil)
        adsManager?.volume = self.volume
    }

    func adsLoader(_ loader: IMAAdsLoader, failedWith adErrorData: IMAAdLoadingErrorData) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                [weak self] in self?.adsLoader(loader, failedWith: adErrorData)
            }
            return
        }
        let message = adErrorData.adError.message ?? "Unknown"

        // Error/no-fill during prefetch — silently mark the session, no analytics.
        if let token = adErrorData.userContext as? String {
            // Late failure for a cancelled prefetch — nothing to mark, and it must not
            // reach the live error path (which would dismiss a currently shown ad).
            if prefetchStore.consumeTombstone(token) { return }
            let isNoFill = message.contains("No Ads VAST")
            if prefetchStore.markLoadFailure(token, isNoFill: isNoFill, message: message) { return }
        }

        let errorMessgae = "BlazeIMAHandler error loading ads: \(message)"
        sharedDelegate.onAdError(errorMessgae)
    }
}

// MARK: - IMAAdsManagerDelegate
extension BlazeIMAHandler: IMAAdsManagerDelegate {

    func adsManager(_ adsManager: IMAAdsManager, didReceive event: IMAAdEvent) {
        // IMA does not contractually guarantee delegate callbacks on the main thread, so marshal
        // onto main before touching main-confined live state. Synchronous no-op on the normal path.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.adsManager(adsManager, didReceive: event) }
            return
        }

        // Events from a held prefetch manager must not run the live flow (which would start()/track).
        // Capture the loaded creative on `.LOADED` so `.adLoaded` can be replayed at show time.
        if let token = prefetchStore.token(for: adsManager) {
            if event.type == .LOADED {
                prefetchStore.markReady(token, ad: event.ad)
            }
            return
        }

        let adInfo = blazeAdInfo(for: event.ad)

        switch event.type {
        case .LOADED:
            adsManager.start()
            sharedDelegate.onAdEvent(eventType: .adLoaded, adInfo: adInfo)
        case .ALL_ADS_COMPLETED:
            sharedDelegate.onAdEvent(eventType: .allAdsCompleted, adInfo: adInfo)
            adsManager.destroy()
            self.adsManager = nil
            self.activeDisplayContainer = nil
            self.loaderNeedsContentComplete = true
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
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.adsManager(adsManager, didReceive: error) }
            return
        }
        if let token = prefetchStore.token(for: adsManager) {
            prefetchStore.markError(token, message: error.message ?? "Unknown")
            return
        }
        let errorMessgae = "BlazeIMAHandler error: \(error.message ?? "Unknown")"
        sharedDelegate.onAdError(errorMessgae)
        self.adsManager = nil
        // Release the held display container too (symmetric with ALL_ADS_COMPLETED). Without
        // this, a prefetched ad that errors after activation strands its container and view
        // hierarchy in memory until the next activation, which may never come.
        self.activeDisplayContainer = nil
        self.loaderNeedsContentComplete = true
    }

    func adsManagerDidRequestContentPause(_ adsManager: IMAAdsManager) {
        // The SDK is going to play ads, so pause any other content.
    }

    func adsManagerDidRequestContentResume(_ adsManager: IMAAdsManager) {
      // The SDK is done playing ads (at least for now), so resume the content.
    }

}

// MARK: - Prefetch
extension BlazeIMAHandler: BlazeIMAPrefetchHandlerProtocol {

    @MainActor
    func prefetchAds(requestData: BlazeIMAAdRequestData,
                     initialVolume: Float,
                     token: String) async {
        // Idempotency: never create a second session for the same token.
        if prefetchStore.hasSession(token) { return }

        let requestExtraInformation = BlazeIMAAdRequestInformation(
            contentExtraInfo: requestData.contentExtraInfo,
            extraInfo: requestData.extraInfo
        )
        let delegateResults = await loadDelegateResults(requestData: .init(requestDataInfo: requestExtraInformation))
        // As in the live path: a client-provided override is used verbatim, never sanitized.
        let tagUrl = delegateResults.overriddenAdTagUrl ?? adTagEnricher.enrichedTagURL(
            requestData: requestData,
            appExtraParams: delegateResults.appExtraParams,
            initialVolume: initialVolume
        )
        
        // A malformed tag would only fail the network request — it will never resolve to a
        // fill no matter how many times it's retried. Register a real `.error` session for it
        // (skipping the network round-trip) instead of returning empty-handed: `IMAPrefetchService`
        // already resolves `.error` to a permanent `.silentSkip`, so an invalid tag never gets
        // a live retry — unlike the transient declines below (no key window / budget cap),
        // which intentionally do fall back to a live request.
        guard tagUrl.isValidAdTagURL else {
            let (offscreenAdViewController, containerView, displayContainer) = makeOffscreenAdDisplayContainer()
            let invalidTagSession = BlazeIMAPrefetchSession(
                token: token,
                offscreenAdViewController: offscreenAdViewController,
                adContainerView: containerView,
                displayContainer: displayContainer,
                adTagUrl: tagUrl,
                extraInfo: requestData.extraInfo,
                status: .error(message: "Invalid ad tag URL")
            )
            _ = prefetchStore.reserve(invalidTagSession)
            return
        }

        // No key window (e.g. player already dismissed) → don't create a hanging session;
        // this is a transient/environmental decline, so the controller falls back to a live
        // request (or times out) rather than being permanently skipped.
        guard keyWindow != nil else {
            return
        }

        resetLoaderDedupIfIdle()
        let loader = obtainSharedLoader(settings: delegateResults.imaSettings)

        // Real but off-screen container. The ad view is reparented onto the real on-screen
        // container when the slot is reached.
        let (offscreenAdViewController, containerView, displayContainer) = makeOffscreenAdDisplayContainer()

        let session = BlazeIMAPrefetchSession(
            token: token,
            offscreenAdViewController: offscreenAdViewController,
            adContainerView: containerView,
            displayContainer: displayContainer,
            adTagUrl: tagUrl,
            extraInfo: requestData.extraInfo,
            status: .requesting
        )

        // Admission re-check after the awaits above, atomic with the insertion: the slot may
        // have been cancelled while no session existed yet (consumes the tombstone), consumed
        // meanwhile, or the global cap may be reached (e.g. another player warmed its slot first).
        guard prefetchStore.reserve(session) == .inserted else { return }

        attachOffScreen(offscreenAdViewController)
        let request = IMAAdsRequest(
            adTagUrl: tagUrl,
            adDisplayContainer: session.displayContainer,
            contentPlayhead: nil,
            userContext: token)
        loader.requestAds(with: request)
    }

    @discardableResult
    func activatePrefetchedAd(token: String,
                              in adContainerView: UIView,
                              adViewController: UIViewController,
                              volume: Float) -> Bool {
        // Main-thread only; dispatchPrecondition is enforced in release builds too.
        dispatchPrecondition(condition: .onQueue(.main))
        guard let ready = prefetchStore.takeReady(token) else { return false }
        let session = ready.session
        let manager = ready.manager
        let loadedAd = ready.ad

        adsManager = manager

        // Point the analytics fields at this ad's request-time values, otherwise every
        // event below would carry the previous live request's tag/extraInfo (or nil).
        mergedOrOverriddenAdTagUrl = session.adTagUrl
        currentContentExtraInfo = session.extraInfo

        // Move the warmed ad view onto the real on-screen container and re-point the
        // display container's view controller, so rendering and click-through happen on
        // the standard BlazeIMAViewController instead of the off-screen holder.
        reparent(session.adContainerView, into: adContainerView)
        session.displayContainer.adContainerViewController = adViewController
        activeDisplayContainer = session.displayContainer
        detach(session.offscreenAdViewController)

        // Fire `.adRequested` before showing the ad so the original player pauses,
        // keeping pause/resume symmetric with the live path.
        sharedDelegate.onAdEvent(eventType: .adRequested, adInfo: blazeAdInfo(for: nil))
        // Replay `.adLoaded` (swallowed during prefetch) for analytics parity with the live path.
        sharedDelegate.onAdEvent(eventType: .adLoaded, adInfo: blazeAdInfo(for: loadedAd))
        // Use the current volume (user may have toggled mute since prefetch), not the prefetch-time value.
        manager.volume = volume

        manager.start()

        return true
    }

    func cancelPrefetch(token: String) {
        // `manager.destroy()` / `detach` touch IMA/UIKit, so this must run on the main thread.
        dispatchPrecondition(condition: .onQueue(.main))
        // The store removes the session or — when none exists yet, or its request is still in
        // flight — tombstones the token so the pending `prefetchAds`/late loader response is
        // dropped instead of leaking into the live flow.
        guard let session = prefetchStore.removeOrTombstone(token) else { return }
        switch session.status {
        case .loading(let manager), .ready(let manager, _):
            manager.destroy()
            loaderNeedsContentComplete = true
        default:
            break
        }
        detach(session.offscreenAdViewController)
    }

    func prefetchState(token: String) -> BlazeIMAPrefetchState? {
        guard let status = prefetchStore.status(token) else { return nil }
        switch status {
        case .requesting: return .requesting
        // Manager exists but ad not preloaded yet — not eligible for instant show.
        case .loading: return .requesting
        case .ready: return .ready
        case .noFill: return .noFill
        case .error: return .error
        }
    }

    func notifyFailedPrefetchReached(token: String, timedOut: Bool) {
        dispatchPrecondition(condition: .onQueue(.main))
       
        guard let session = prefetchStore.session(token) else { return }
        
        let reason: String
        switch session.status {
        case .error(let message):
            reason = message
        case .noFill:
            reason = "no ads available"
        case .requesting, .loading:
            // In-flight → a failure only if the service timed it out.
            guard timedOut else { return }
            reason = "ad request timed out"
        case .ready:
            return
        }
        // Use this session's tag/extraInfo (like activatePrefetchedAd), not the last live request's.
        mergedOrOverriddenAdTagUrl = session.adTagUrl
        currentContentExtraInfo = session.extraInfo
        // Client delegate only (see `SharedDelegate`).
        sharedDelegate.onAppDelegateAdEvent(eventType: .adRequested, adInfo: blazeAdInfo(for: nil))
        sharedDelegate.onAppDelegateAdError("BlazeIMAHandler error loading ads: \(reason)")
    }

    // MARK: Private prefetch helpers

    /// Builds a fresh off-screen ad view controller + container + display container triple.
    /// Used both for a real prefetch reservation and for registering an invalid-tag session
    /// that's never attached to the window (see the `isValidAdTagURL` guard above).
    @MainActor
    private func makeOffscreenAdDisplayContainer() -> (viewController: UIViewController,
                                                        containerView: UIView,
                                                        displayContainer: IMAAdDisplayContainer) {
        let offscreenAdViewController = BlazeIMAPrefetchContainerViewController()
        offscreenAdViewController.loadViewIfNeeded()
        let containerView = offscreenAdViewController.adViewContainer
        let displayContainer = IMAAdDisplayContainer(adContainer: containerView,
                                                      viewController: offscreenAdViewController,
                                                      companionSlots: nil)
        return (offscreenAdViewController, containerView, displayContainer)
    }

    private func handlePrefetchAdsLoaded(token: String, adsManager manager: IMAAdsManager?) {
        guard let manager else {
            prefetchStore.markNoFill(token)
            return
        }
        // Store the manager before initialize() so its events route to prefetch, not live;
        // status becomes `.ready` only once the manager fires `.LOADED`.
        guard prefetchStore.markLoading(token, manager: manager) else { return }

        manager.delegate = self
        let renderingSettings = IMAAdsRenderingSettings()
        renderingSettings.enablePreloading = true
        manager.initialize(with: renderingSettings)
    }

    // MARK: Off-screen view lifecycle

    private var keyWindow: UIWindow? {
        if let windowOverrideForTesting { return windowOverrideForTesting }
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        return windows.first(where: { $0.isKeyWindow }) ?? windows.first
    }

    private func attachOffScreen(_ viewController: UIViewController) {
        guard let window = keyWindow else { return }
        viewController.loadViewIfNeeded()
        guard let view = viewController.view else { return }
        window.addSubview(view)
        view.isUserInteractionEnabled = false
        // Full-size but off-screen — the view is live but invisible. Constraints
        // (not a one-shot frame) keep it off-screen through rotation and Split View
        // resizes; `reparent` removes the view from the window, which drops them.
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.trailingAnchor.constraint(equalTo: window.leadingAnchor),
            view.topAnchor.constraint(equalTo: window.topAnchor),
            view.widthAnchor.constraint(equalTo: window.widthAnchor),
            view.heightAnchor.constraint(equalTo: window.heightAnchor)
        ])
    }

    /// Moves the warmed ad container view from its off-screen holder into the real
    /// on-screen container, pinned to its edges.
    private func reparent(_ adView: UIView, into container: UIView) {
        adView.removeFromSuperview()
        adView.translatesAutoresizingMaskIntoConstraints = false
        adView.isUserInteractionEnabled = true
        container.addSubview(adView)
        NSLayoutConstraint.activate([
            adView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            adView.topAnchor.constraint(equalTo: container.topAnchor),
            adView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func detach(_ viewController: UIViewController) {
        viewController.viewIfLoaded?.removeFromSuperview()
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
