//
//  Locale.swift
//  Pods
//
//  Created by Nick Lee on 1/26/16.
//
//

import Foundation
import Zip

@objc public final class Locale: NSObject {

    // MARK: Singleton

    public static let sharedInstance = Locale()

    // MARK: Private Properties

    private let fileManager = NSFileManager.defaultManager()

    private var localizations: [String : AnyObject] = [
        Constants.BaseLocaleName : Dictionary<String, AnyObject>()
    ]

    private var activeLocalization: [String : AnyObject] {
        // TODO: Fix
        return localizations[Constants.BaseLocaleName] as? [String : AnyObject] ?? [:]
    }

    // MARK: Initialization

    private override init() {
        super.init()
    }

    // MARK: Loading

    public func load(bundleURL: NSURL, password: String? = nil) throws {
        let temporaryDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent(Constants.TemporaryDirectoryName, isDirectory: true)

        do {
            try fileManager.removeItemAtURL(temporaryDirectory)
        } catch {}

        try fileManager.createDirectoryAtURL(temporaryDirectory, withIntermediateDirectories: true, attributes: nil)

        try Zip.unzipFile(bundleURL, destination: temporaryDirectory, overwrite: true, password: password, progress: nil)

        try loadLocalizations(temporaryDirectory)
    }

    private func loadLocalizations(path: NSURL) throws {

        let localizationDirectory = path.URLByAppendingPathComponent(Constants.LocalizationDirectoryName, isDirectory: true)

        var isDirectory: ObjCBool = false
        guard fileManager.fileExistsAtPath(localizationDirectory.path!, isDirectory: &isDirectory) && isDirectory.boolValue else {
            return
        }

        guard let enumerator = fileManager.enumeratorAtURL(localizationDirectory, includingPropertiesForKeys: nil, options: [], errorHandler: nil) else {
            return
        }

        let urls = enumerator.allObjects.flatMap { $0 as? NSURL }

        let data = urls.flatMap { url -> (NSURL, NSData)? in
            guard let data = NSData(contentsOfURL: url) else {
                return nil
            }
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
