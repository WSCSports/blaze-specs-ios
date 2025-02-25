//
//  BlazeAdServerParamsBuilder.swift
//  BlazeSDK
//
//  Created by Dor Zafrir on 10/02/2025.
//  Copyright © 2025 com.WSCSports. All rights reserved.
//

import Foundation
import BlazeSDK
import AppTrackingTransparency
import AdSupport

enum AdServerParamsBuilder {
    
    static func createInternalEnrichedQueryItems(context: [String: String],
                                                 initialVolume: Float,
                                                 adServerType: BlazeAdInfoModel.AdServerType?) -> [String: String] {
        var result = createBaseQueryItems(initialVolume: initialVolume)
                
        // Add server-specific parameters based on type
        switch adServerType {
        case .aniview:
            result.merge(createAniviewParams()) { (_, new) in new }
        default: break
        }
        
        if !context.isEmpty {
            result[BlazeIMAConstants.IMACustParamsKeyName] = createCustParamsString(from: context)
        }
        
        return result
    }
    
    private static func createCustParamsString(from params: [String: String]) -> String {
        params.map {
            let encodedValue = $0.value.urlEncodedForQueryCustParamValue ?? ""
            return "\($0.key)=\(encodedValue)"
        }.joined(separator: "&")
    }
}

//MARK: `Base` Custom Params
extension AdServerParamsBuilder {
    private static func createBaseQueryItems(initialVolume: Float) -> [String: String] {
        let isMuted = initialVolume == 0
        return [
            BlazeIMAConstants.vpmuteParam.key: BlazeIMAConstants.vpmuteParam.valueFor(isMuted: isMuted),
            BlazeIMAConstants.plcmtParam.key: BlazeIMAConstants.plcmtParam.value,
            BlazeIMAConstants.vposParam.key: BlazeIMAConstants.vposParam.value,
            BlazeIMAConstants.vpaParam.key: BlazeIMAConstants.vpaParam.value
        ]
    }
}

//MARK: `Aniview` AdServer Custom Params
extension AdServerParamsBuilder {
    private static func createAniviewParams() -> [String: String] {
        var params = [
            BlazeIMAConstants.AniviewCustomParams.bundleIdKey: getBundleId(),
            BlazeIMAConstants.AniviewCustomParams.appName: getAppName(),
        ]
        
        // Add AV_AID only if we have permission and can get a valid IDFA
        if let advertisingId = getAdvertisingId() {
            params[BlazeIMAConstants.AniviewCustomParams.aid] = advertisingId
        }
        
        return params
    }
}


//MARK: Helpers - Static Getters
extension AdServerParamsBuilder {
    
    private static func getBundleId() -> String {
        Bundle.main.bundleIdentifier ?? ""
    }
    
    private static func getAppName() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }
    
    private static func getAdvertisingId() -> String? {
        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .authorized {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
            return nil
        } else {
            // For iOS versions below 14
            return ASIdentifierManager.shared().isAdvertisingTrackingEnabled ?
            ASIdentifierManager.shared().advertisingIdentifier.uuidString :
            nil
        }
    }
}
