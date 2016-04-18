//
//  Locale.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation
import zipzap

private let languageComponents = NSLocale.componentsFromLocaleIdentifier(NSLocale.currentLocale().localeIdentifier)
private let languageCode = languageComponents[NSLocaleLanguageCode] ?? Constants.BaseLocaleName
private let countryCode = languageComponents[NSLocaleCountryCode] ?? ""
private let scriptCode = languageComponents[NSLocaleScriptCode]

@objc public final class Locale: NSObject {

    // MARK: Singleton

    public static let sharedInstance = Locale()

    // MARK: Private Properties

    private typealias LocalizationMap = [String : AnyObject]
    
    private let fileManager = NSFileManager.defaultManager()
    
    private var localizations: [String : AnyObject] = [
        Constants.BaseLocaleName : Dictionary<String, AnyObject>()
    ]

    private var activeLocalization: LocalizationMap {
        if let script = scriptCode, loc = localizations[languageCode + "-" + script] as? LocalizationMap {
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
    
    private let mutex = dispatch_semaphore_create(1)

    // MARK: Initialization

    private override init() {
        super.init()
    }
    
    // MARK: Loading

    public func load(bundleURL: NSURL) throws {
        dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER)
        defer { dispatch_semaphore_signal(mutex) }
        let archive: ZZArchive = try {
            let cachedPath = Constants.CachedLocalizationArchivePath
            let cachedURL = NSURL(fileURLWithPath: cachedPath)
            if let cached = try? ZZArchive(URL: cachedURL) {
                return cached
            }
            return try ZZArchive(URL: bundleURL)
        }()
        let entries = archive.entries.filter { $0.fileName.hasSuffix(".json") }
        let localizationEntries = entries.filter { $0.fileName.hasPrefix(Constants.LocalizationDirectoryName) }
        try loadLocalizations(localizationEntries)
    }

    private func loadLocalizations(entries: [ZZArchiveEntry]) throws {

        let data = try entries.flatMap { entry -> (NSURL, NSData)? in
            let url = NSURL(fileURLWithPath: entry.fileName)
            let data = try entry.newData()
            return (url, data)
        }

        let jsonObjects = try data.flatMap { (url, data) -> (NSURL, LocalizationMap)? in
            guard let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as? LocalizationMap else {
                throw LocaleKitError.FailedToParseJSON(path: url.absoluteString)
            }
            return (url, json)
        }

        let locales = jsonObjects.flatMap { (url, json) -> (String, LocalizationMap)? in
            guard let components = url.pathComponents where components.count >= 2 else {
                return nil
            }
            let directory = components[components.count - 2]
            return (directory, json)
        }

        for (locale, data) in locales {
            let target = (localizations[locale] as? LocalizationMap) ?? (locale == Constants.BaseLocaleName ? [:] : localizations[Constants.BaseLocaleName] as? LocalizationMap) ?? [:]
            let merged = deepMerge(target, data)
            localizations[locale] = merged
        }

    }
    
    public class func activeLocaleEqualsCode(identifier: String) -> Bool {
        
        let localeIdentifier = NSLocale.currentLocale().objectForKey(NSLocaleIdentifier) as! String
        
        return localeIdentifier == identifier
        
    }
    
    public class func activeLanguageEqualsCode(identifier: String) -> Bool {
        
        return identifier == languageCode
        
    }
    
    public class func activeCountryEqualsCode(identifier: String) -> Bool {
        
        return identifier == countryCode
        
    }

    // MARK: Localizations

    public class func group(group: AnyObject) -> LPath {
        return LPath(components: [String(group)])
    }

    internal func traverse(components: [String]) -> AnyObject? {
        dispatch_semaphore_wait(mutex, DISPATCH_TIME_FOREVER)
        defer { dispatch_semaphore_signal(mutex) }
        var comps = components
        var currentValue: AnyObject? = activeLocalization
        while comps.count > 0 {
            let component = comps.removeFirst()
            currentValue = (currentValue as? LocalizationMap)?[component]
        }
        return currentValue
    }

}
