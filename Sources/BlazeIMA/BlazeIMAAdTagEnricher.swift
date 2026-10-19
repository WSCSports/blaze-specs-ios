//
//  BlazeIMAAdTagEnricher.swift
//
//
//  Created by Reuven Levitsky on 19/09/2024.
//

import Foundation
import BlazeSDK

class BlazeIMAAdTagEnricher {

    // Scalar params only: these bypass updateTagURL's nested cust_params merging.
    // Also the only params whose duplicates are collapsed - every other param keeps
    // updateTagURL's replace-first-match-only behavior.
    // The forced pass stands on its own - it doesn't rely on the earlier merge passes
    // having seeded the tag's query items.
    private static let forcedQueryItems: [String: String] = [
        BlazeIMAConstants.adRuleParam.key: BlazeIMAConstants.adRuleParam.value
    ]

    func enrichedTagURL(requestData: BlazeIMAAdRequestData,
                        appExtraParams: [String: String],
                        initialVolume: Float) -> String {
        // Sanitize first - a raw bracket/space macro would otherwise fail URLComponents parsing below.
        let sanitizedAdTag = requestData.adTag.sanitizedAdTagURL

        // Add internal query items - priotise existing current tag query items.
        let internalEnrichedExtraParams = AdServerParamsBuilder.createInternalEnrichedQueryItems(context: requestData.context,
                                                                                                 initialVolume: initialVolume,
                                                                                                 adServerType: requestData.adServerType)

        var modifiedTag = updateTagURL(adTag: sanitizedAdTag,
                                       with: internalEnrichedExtraParams,
                                       shouldReplace: false)
        
        // Add app side query items - prioritise those over existing tag query items.
        modifiedTag = updateTagURL(adTag: modifiedTag,
                                   with: appExtraParams,
                                   shouldReplace: true)

        // Forced params win over both the client's tag and appExtraParams: a non-zero ad_rule
        // makes GAM return a Playlist, which the SDK cannot play.
        modifiedTag = forcedTagURL(adTag: modifiedTag)

        return modifiedTag
    }

    /// Applies the forced query items, overriding whatever the tag or `appExtraParams` carried.
    /// Kept separate from `updateTagURL` so the existing merge passes are untouched.
    private func forcedTagURL(adTag: String) -> String {
        guard var urlComponents = URLComponents(string: adTag) else {
            return adTag
        }

        Self.forcedQueryItems.forEach { key, value in
            urlComponents.setOnlyQueryItemWithName(key, newValue: value)
        }

        return urlComponents.url?.absoluteString ?? adTag
    }

    /// Adds the given query items to the given adTag.
    /// The QueryItem `cust_params` will be an exception since it's a key value property - so any merge on this one will be nested and will not replace the entire existing object.
    ///
    /// - Parameters:
    ///   - adTag: The initial adTag url.
    ///   - newQueryItems: The new Query Params to add.
    ///   - shouldReplace: If true - if the adTag URL already has one of the new items - the new value will replace it. If false - the existing query item will remain.
    ///
    /// - Returns: the updated tag URL.
    func updateTagURL(adTag: String,
                      with newQueryItems: [String: String],
                      shouldReplace: Bool) -> String {
        // Convert the base tag string to URLComponents
        guard var urlComponents = URLComponents(string: adTag) else {
            return adTag
        }
        
        // If queryItems is nil, initialize it before appending
        urlComponents.createQueryItemsIfEmpty()
        
        newQueryItems.forEach { key, value in
            guard key != BlazeIMAConstants.IMACustParamsKeyName else {
                // IMA's cust_params is special, it's a nested Query string inside the Tag's query.
                // So when merging this one with a new value we always merge the two values and replace the existing value with the merged result.
                // https://support.google.com/admanager/answer/1080597
                let currentCustParams = urlComponents.firstQueryItemWithName(key)
                let updatedCustParamsValue = updatedCustParamsQueryItemValue(currentCustParams: currentCustParams?.value,
                                                                            additionalCustParams: value)
                
                urlComponents.setQueryItemWithName(key,
                                                   newValue: updatedCustParamsValue,
                                                   shouldReplace: true)
                
                return
            }

            urlComponents.setQueryItemWithName(key,
                                               newValue: value,
                                               shouldReplace: shouldReplace)
        }
        
        let modifiedTagURL = urlComponents.url
        return modifiedTagURL?.absoluteString ?? adTag
    }
    
    private func updatedCustParamsQueryItemValue(currentCustParams: String?, additionalCustParams: String) -> String {
        // Convert the base tag string to URLComponents
        guard let currentCustParams = currentCustParams else {
            return additionalCustParams
        }

        return "\(currentCustParams)&\(additionalCustParams)"
    }
    
}
