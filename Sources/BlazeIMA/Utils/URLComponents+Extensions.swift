//
//  URLComponents+Extensions.swift
//  
//
//  Created by Reuven Levitsky on 18/09/2024.
//

import Foundation

extension URLComponents {
    
    mutating func createQueryItemsIfEmpty() {
        if queryItems == nil {
            queryItems = []
        }
    }
    
    func hasQueryItemWithName(_ name: String) -> Bool {
        return firstIndexOfQueryItemWithName(name) != nil
    }
    
    func firstIndexOfQueryItemWithName(_ name: String) -> Int? {
        let index = queryItems?.firstIndex(where: { $0.name == name })
        return index
    }
    
    func firstQueryItemWithName(_ name: String) -> URLQueryItem? {
        let index = queryItems?.first(where: { $0.name == name })
        return index
    }
    
    func allQueryItemsWithName(_ name: String) -> [URLQueryItem]? {
        let allItems = queryItems?.filter({ $0.name == name })
        return allItems
    }
    
    mutating func replaceQueryItemWithName(_ name: String, newValue: String) {
        guard let itemIndex = firstIndexOfQueryItemWithName(name) else { return }
        
        queryItems?[itemIndex] = URLQueryItem(name: name, value: newValue)
    }
    
    /// Unlike `replaceQueryItemWithName`, which replaces the first match only, this collapses every occurrence into a single item.
    /// Safe when `queryItems` is `nil` - it seeds the array rather than silently doing nothing.
    mutating func setOnlyQueryItemWithName(_ name: String, newValue: String) {
        var items = queryItems ?? []
        items.removeAll { $0.name == name }
        items.append(URLQueryItem(name: name, value: newValue))
        queryItems = items
    }

    mutating func setQueryItemWithName(_ name: String, newValue: String, shouldReplace: Bool) {
        if hasQueryItemWithName(name) {
            if shouldReplace {
                replaceQueryItemWithName(name, newValue: newValue)
                return
            } else {
                // If there's such query item and we were asked not to replace - we bail out.
                return
            }
        }
        
        // Append each extra parameter as a query item
        let queryItem = URLQueryItem(name: name, value: newValue)
        queryItems?.append(queryItem)
    }
    
}
