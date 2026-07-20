//
//  BlazeIMAShared.swift
//
//
//  Created by Dor Zafrir on 13/06/2024.
//

import Foundation
import BlazeSDK


/// A singleton class that provides methods to enable or disable IMA ads using the Blaze SDK.
///
/// ## Thread Safety
///
/// All public methods on this class always perform their work on the main thread
/// internally and are asynchronous. They are therefore safe to call from any thread.
///
/// This is required because the underlying Google IMA SDK uses a `WKWebView`,
/// whose dealloc chain (triggered when the handler is released) must run on the
/// main thread — enforced as a hard assertion on iOS 18+.
///
/// Because the work is dispatched asynchronously, side-effects (e.g. the internally
/// registered IMA handler being nil-ed out by `disableAds()`) take effect on
/// the next main-queue tick. Back-to-back calls preserve FIFO order.
public class BlazeIMA {
    
    //MARK: - Public Properties
    
    /// Shared instance to access the sdk methods
    public static let shared = BlazeIMA()
    
    //MARK: Public methods
    
    /// Enables ads by initializing the IMA handler.
    ///
    /// Call this method to start displaying IMA ads in your application.
    ///
    /// - Note: The work is always performed on the main thread internally and is
    ///   asynchronous. See the class-level *Thread Safety* note.
    public func enableAds(delegate: BlazeIMADelegate?) {
        DispatchQueue.main.async {
            let imaHandler = BlazeIMAHandler()
            imaHandler.appDelegate = delegate
            BlazeExternalModulesBinder.shared.registerIMAHandler(imaHandler)
        }
    }
    
    /// Disables IMA ads.
    ///
    /// Call this method to stop displaying IMA ads.
    ///
    /// - Note: The work is always performed on the main thread internally and is
    ///   asynchronous. See the class-level *Thread Safety* note.
    public func disableAds() {
        DispatchQueue.main.async {
            BlazeExternalModulesBinder.shared.registerIMAHandler(nil)
        }
    }
}
