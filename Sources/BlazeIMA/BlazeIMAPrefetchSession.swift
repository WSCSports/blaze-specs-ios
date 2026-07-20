//
//  BlazeIMAPrefetchSession.swift
//  BlazeIMA
//
//  Created by Max Lukashevich on 19/06/2026.
//  Copyright © 2026 com.WSCSports. All rights reserved.
//

import UIKit
import GoogleInteractiveMediaAds
import BlazeSDK

enum IMAPrefetchStatus {
    case requesting
    /// Manager exists and event routing is active, but the ad has not been preloaded yet
    /// (no `.LOADED` event). Not eligible for instant show.
    case loading(adsManager: IMAAdsManager)
    /// Ad is preloaded (manager fired `.LOADED`); `ad` carries the loaded creative for analytics parity.
    case ready(adsManager: IMAAdsManager, ad: IMAAd?)
    case noFill
    case error(message: String)
}

struct BlazeIMAPrefetchSession {
    let token: String
    let offscreenAdViewController: UIViewController
    let adContainerView: UIView
    /// Retained so the ad's container view controller can be re-pointed to the real
    /// presented screen at show time (its `adContainerViewController` is a weak property).
    let displayContainer: IMAAdDisplayContainer
    /// Request-time values for analytics. `blazeAdInfo` reads the handler-level fields,
    /// which are only written by the live request path — without these a prefetched ad
    /// would report the previous live ad's tag/extraInfo (or nil).
    let adTagUrl: String
    let extraInfo: BlazeContentExtraInfo
    var status: IMAPrefetchStatus
}

/// Lightweight container for an off-screen IMA ad request during prefetch.
/// `BlazeIMAViewController` is internal to BlazeSDK and unavailable from BlazeIMA,
/// so a simple dedicated container is used here.
final class BlazeIMAPrefetchContainerViewController: UIViewController {

    let adViewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(adViewContainer)
        NSLayoutConstraint.activate([
            adViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            adViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            adViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            adViewContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
