//
//  DictionaryExtensions.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation

// Thanks: http://stackoverflow.com/questions/32929981/how-to-deep-merge-2-swift-dictionaries
internal func deepMerge(d1: [String:AnyObject], _ d2: [String:AnyObject]) -> [String:AnyObject] {
    var result = [String:AnyObject]()
    for (k1, v1) in d1 {
        result[k1] = v1
    }
    for (k2, v2) in d2 {
        if v2 is [String:AnyObject], let v1 = result[k2] where v1 is [String:AnyObject] {
            result[k2] = deepMerge(v1 as! [String:AnyObject], v2 as! [String:AnyObject])
        } else {
            result[k2] = v2
        }
    }
    return result
}
