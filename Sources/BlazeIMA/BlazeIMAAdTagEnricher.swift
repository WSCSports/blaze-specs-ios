//
//  BlazeIMAAdTagEnricher.swift
//
//
//  Created by Reuven Levitsky on 19/09/2024.
//

import Foundation
import BlazeSDK

class BlazeIMAAdTagEnricher {
    
    func enrichedTagURL(requestData: BlazeIMAAdRequestData,
                        appExtraParams: [String: String],
                        initialVolume: Float) -> String {
        // Add internal query items - priotise existing current tag query items.
        let internalEnrichedExtraParams = AdServerParamsBuilder.createInternalEnrichedQueryItems(context: requestData.context,
                                                                                                 initialVolume: initialVolume,
                                                                                                 adServerType: requestData.adServerType)
        
        var modifiedTag = updateTagURL(adTag: requestData.adTag,
                                       with: internalEnrichedExtraParams,
                                       shouldReplace: false)
        
        // Add app side query items - prioritise those over existing tag query items.
        modifiedTag = updateTagURL(adTag: modifiedTag,
                                   with: appExtraParams,
                                   shouldReplace: true)
        
        return modifiedTag
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
