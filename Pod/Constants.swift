//
//  Constants.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation

public struct Constants {
    internal static let TemporaryDirectoryName = ".localekit"
    internal static let LocalizationDirectoryName = "localizable"
    internal static let FileExtension = "json"
    internal static let BaseLocaleName = "base"
    internal static let DefaultUpdateInterval: TimeInterval = 24 * 60 * 60 // 24 hours / day * 60 minutes / hour * 60 seconds / minute
    internal static let LastUpdatedDefaultsKey = "TDLocaleKitLastUpdated"
    internal static let LibraryPath = (NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first! as NSString).appendingPathComponent("TDLocaleKit")
    public static let CachedLocalizationArchivePath = (Constants.LibraryPath as NSString).appendingPathComponent("locale.zip")
    internal static var isSimulator: Bool {
        #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
        #else
            return false
        #endif
    }
}
