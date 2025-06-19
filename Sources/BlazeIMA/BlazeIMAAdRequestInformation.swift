//
//  BlazeIMAAdRequestInformation.swift
//  BlazeSDK
//
//  Created by Dor Zafrir on 20/02/2025.
//  Copyright © 2025 com.WSCSports. All rights reserved.
//

import BlazeSDK

public struct BlazeIMAAdRequestInformation {
    @available(*, deprecated, message: "Use 'extraInfo' instead. This field will be removed in a future release")
    public let contentExtraInfo: [String: String]
    
    /// New field replacing the deprecated `contentExtraInfo`, contains previous/current/next extra info.
    public let extraInfo: BlazeContentExtraInfo
}
