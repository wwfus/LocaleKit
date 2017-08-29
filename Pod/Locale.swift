//
//  Locale.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation
import zipzap

private let languageComponents = Foundation.Locale.components(fromIdentifier: Foundation.Locale.current.identifier)
private let languageCode = languageComponents[NSLocale.Key.languageCode.rawValue] ?? Constants.BaseLocaleName
private let countryCode = languageComponents[NSLocale.Key.countryCode.rawValue]
private let scriptCode = languageComponents[NSLocale.Key.scriptCode.rawValue]

@objc public final class Locale: NSObject {

    // MARK: Singleton

    public static let sharedInstance = Locale()

    /// The device's language code
    public static var lc: String {
        if let sc = scriptCode {
            return "\(languageCode)-\(sc)"
        } else {
            return languageCode
        }
    }
    
    /// The device's country code
    public static let cc = countryCode
    
    // MARK: Private Properties

    fileprivate typealias LocalizationMap = [String : AnyObject]
    
    fileprivate let fileManager = FileManager.default
    
    fileprivate var localizations: [String : AnyObject] = [
        Constants.BaseLocaleName : Dictionary<String, AnyObject>() as AnyObject
    ]

    fileprivate var activeLocalization: LocalizationMap {
        let c1 = [languageCode, scriptCode].flatMap({ $0 }).joined(separator: "-")
        let fullComponentString = [c1, countryCode].flatMap({ $0 }).joined(separator: "_")
        if let loc = localizations[fullComponentString] as? LocalizationMap {
            return loc
        }
        else if let script = scriptCode, let loc = localizations[languageCode + "-" + script] as? LocalizationMap {
            return loc
        }
        else if let country = countryCode, let loc = localizations[languageCode + "_" + country] as? LocalizationMap {
            return loc
        }
        else if let loc = localizations[languageCode] as? LocalizationMap {
            return loc
        }
        else if let loc = localizations[Constants.BaseLocaleName] as? LocalizationMap {
            return loc
        }
        return [:]
    }
    
    fileprivate let mutex = DispatchSemaphore(value: 1)

    // MARK: Initialization

    fileprivate override init() {
        super.init()
    }
    
    // MARK: Loading

    public func load(_ bundleURL: URL) throws {
        mutex.wait(timeout: DispatchTime.distantFuture)
        defer { mutex.signal() }
        let archive: ZZArchive = try {
            let cachedPath = Constants.CachedLocalizationArchivePath
            let cachedURL = URL(fileURLWithPath: cachedPath)
            if let cached = try? ZZArchive(url: cachedURL) {
                return cached
            }
            return try ZZArchive(url: bundleURL)
        }()
        let entries = archive.entries.filter { $0.fileName.hasSuffix(".json") }
        let localizationEntries = entries.filter { $0.fileName.hasPrefix(Constants.LocalizationDirectoryName) }
        try loadLocalizations(localizationEntries)
    }

    fileprivate func loadLocalizations(_ entries: [ZZArchiveEntry]) throws {

        let data = try entries.flatMap { entry -> (URL, Data)? in
            let url = URL(fileURLWithPath: entry.fileName)
            let data = try entry.newData()
            return (url, data)
        }

        let jsonObjects = try data.flatMap { (url, data) -> (URL, LocalizationMap)? in
            guard let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? LocalizationMap else {
                throw LocaleKitError.failedToParseJSON(path: url.absoluteString)
            }
            return (url, json)
        }

        let locales = jsonObjects.flatMap { (url, json) -> (String, LocalizationMap)? in
            let components = url.pathComponents
            guard components.count >= 2 else {
                return nil
            }
            let directory = components[components.count - 2]
            return (directory, json)
        }

        for (locale, data) in locales {
            let target = (localizations[locale] as? LocalizationMap) ?? (locale == Constants.BaseLocaleName ? [:] : localizations[Constants.BaseLocaleName] as? LocalizationMap) ?? [:]
            let merged = deepMerge(target, data)
            localizations[locale] = merged as AnyObject
        }

    }
    
    public class func activeLocaleEqualsCode(_ identifier: String) -> Bool {
        let localeIdentifier = (Foundation.Locale.current as NSLocale).object(forKey: NSLocale.Key.identifier) as! String
        return localeIdentifier == identifier
    }
    
    public class func activeLanguageEqualsCode(_ identifier: String) -> Bool {
        return identifier == languageCode
    }
    
    public class func activeCountryEqualsCode(_ identifier: String) -> Bool {
        return identifier == countryCode
    }

    // MARK: Localizations

    public class func group(_ group: Any) -> LPath {
        return LPath(components: [String(describing: group)])
    }

    internal func traverse(_ components: [String]) -> AnyObject? {
        mutex.wait(timeout: DispatchTime.distantFuture)
        defer { mutex.signal() }
        var comps = components
        var currentValue: AnyObject? = activeLocalization as AnyObject?
        while comps.count > 0 {
            let component = comps.removeFirst()
            currentValue = (currentValue as? LocalizationMap)?[component]
        }
        return currentValue
    }

}
