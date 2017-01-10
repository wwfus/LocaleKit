//
//  Error.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation

enum LocaleKitError: Error {
    case failedToParseJSON(path: String)
    case failedToWriteData
}
