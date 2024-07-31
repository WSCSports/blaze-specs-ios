//
//  BlazeIMAShared.swift
//
//
//  Created by Dor Zafrir on 13/06/2024.
//

import Foundation
import BlazeSDK


/// A singleton class that provides methods to enable or disable IMA ads using the Blaze SDK.
public class BlazeIMA {
    
    //MARK: - Public Properties
    
    /// Shared instance to access the sdk methods
    public static let shared = BlazeIMA()
    
    //MARK: Public methods
    
    /// Enables ads by initializing the IMA handler
    ///
    /// Call this method to start displaying IMA ads in your application
    ///
    /// - Note: Enabling and disabling ads are not thread-safe. It's your responsibility to make sure you are enabling and disabling ads from the same thread.
    public func enableAds(delegate: BlazeIMADelegate?) {
        let imaHandler = BlazeIMAHandler()
        imaHandler.appDelegate = delegate
        Blaze.shared.imaHandler = imaHandler
    }
    
    /// Disables IMA ads
    ///
    /// Call this method to stop displaying IMA ads.
    ///
    /// - Note: Enabling and disabling ads are not thread-safe. It's your responsibility to make sure you are enabling and disabling ads from the same thread.
    public func disableAds() {
        Blaze.shared.imaHandler = nil
    }

 
}
