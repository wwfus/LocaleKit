//
//  Error.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation

enum LocaleKitError: ErrorType {
    case FailedToParseJSON(path: String)
    case FailedToWriteData
}
