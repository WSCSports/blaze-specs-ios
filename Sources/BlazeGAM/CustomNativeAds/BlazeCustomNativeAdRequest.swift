//
//  BlazeCustomNativeAdRequest.swift
//
//
//  Created by Dor Zafrir on 19/06/2024.
//

import Foundation
import GoogleMobileAds

final class BlazeCustomNativeAdRequest: Equatable {
    static func == (lhs: BlazeCustomNativeAdRequest, rhs: BlazeCustomNativeAdRequest) -> Bool {
        lhs.adLoader == rhs.adLoader && lhs.templateId == rhs.templateId
    }

    init(adLoader: AdLoader,
         completion: @escaping (CustomNativeAd?, Error?) -> Void,
         templateId: String) {
        self.adLoader = adLoader
        self.completion = completion
        self.templateId = templateId
    }

    let adLoader: AdLoader
    let completion: (CustomNativeAd?, Error?) -> Void
    let templateId: String
}
