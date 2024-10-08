//
//  BlazeIMAConstants.swift
//  
//
//  Created by Reuven Levitsky on 19/09/2024.
//

import Foundation

struct BlazeIMAConstants {
    
    static let IMACustParamsKeyName = "cust_params"
    static let vpmuteParam: VPMute = .init(key: "vpmute")
    static let plcmtParam: StaticValueParam = .init(key: "plcmt", value: "1")
    static let vposParam: StaticValueParam = .init(key: "vpos", value: "midroll")
    static let vpaParam: StaticValueParam = .init(key: "vpa", value: "auto")
    
    struct StaticValueParam {
        let key: String
        let value: String
    }
    
    struct VPMute {
        let key: String
        
        func valueFor(isMuted: Bool) -> String {
            isMuted ? "1" : "0"
        }
    }
    
}
