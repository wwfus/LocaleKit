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
        return [:]
    }

    // MARK: Initialization

    private override init() {
        super.init()
    }

    // MARK: Loading

    public func load(bundleURL: NSURL, password: String? = nil) throws {

        let archive = try ZZArchive(URL: bundleURL)
        
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

        let jsonObjects = try data.flatMap { (url, data) -> (NSURL, [String : AnyObject])? in
            guard let json = (try? NSJSONSerialization.JSONObjectWithData(data, options: [])) as? [String : AnyObject] else {
                throw LocaleKitError.FailedToParseJSON(path: url.absoluteString)
            }
            return (url, json)
        }

        let locales = jsonObjects.flatMap { (url, json) -> (String, [String : AnyObject])? in
            guard let components = url.pathComponents where components.count >= 2 else {
                return nil
            }
            let directory = components[components.count - 2]
            return (directory, json)
        }

        for (locale, data) in locales {
            let target = (localizations[locale] as? [String : AnyObject]) ?? (locale == Constants.BaseLocaleName ? [:] : localizations[Constants.BaseLocaleName] as? [String : AnyObject]) ?? [:]
            localizations[locale] = deepMerge(target, data)
        }

    }

    // MARK: Localizations

    public class func group(group: AnyObject) -> LPath {
        return LPath(components: [String(group)])
    }

    internal func traverse(var components: [String]) -> AnyObject? {
        var currentValue: AnyObject? = activeLocalization
        while components.count > 0 {
            let component = components.removeFirst()
            currentValue = (currentValue as? [String : AnyObject])?[component]
        }
        return currentValue
    }

}
