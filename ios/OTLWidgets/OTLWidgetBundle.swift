//
//  OTLWidgetBundle.swift
//  OTLWidgetsExtension
//
//  Created by Soongyu Kwon on 28/03/2023.
//  Copyright © 2023 The Chromium Authors. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents
import Darwin
import Security

struct WidgetTokenPair: Codable {
    let accessToken: String
    let refreshToken: String

    var isValid: Bool {
        !accessToken.isEmpty && !refreshToken.isEmpty
    }
}

enum WidgetTokenVaultError: LocalizedError {
    case invalidTokenPair
    case keychain(OSStatus)
    case lockUnavailable
    case lockFailed(Int32)

    var errorDescription: String? {
        switch self {
        case .invalidTokenPair:
            return "Token pair is missing or invalid."
        case .keychain(let status):
            return SecCopyErrorMessageString(status, nil) as String? ?? "Keychain error \(status)."
        case .lockUnavailable:
            return "Shared token vault container is unavailable."
        case .lockFailed(let code):
            return "Shared token vault lock failed (\(code))."
        }
    }
}

private enum WidgetTokenVaultLock {
    static let appGroup = "group.org.sparcs.otl"
    private static let fileName = "token-vault.lock"

    static func withLock<T>(_ operation: () throws -> T) throws -> T {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        ) else {
            throw WidgetTokenVaultError.lockUnavailable
        }
        let descriptor = open(
            container.appendingPathComponent(fileName).path,
            O_CREAT | O_RDWR,
            S_IRUSR | S_IWUSR
        )
        guard descriptor >= 0 else {
            throw WidgetTokenVaultError.lockFailed(errno)
        }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else {
            throw WidgetTokenVaultError.lockFailed(errno)
        }
        defer { flock(descriptor, LOCK_UN) }
        return try operation()
    }
}

enum WidgetRefreshLease {
    private static let fileName = "token-refresh.lock"
    private static let timeout: TimeInterval = 15

    static func acquire() -> Int32? {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: WidgetTokenVaultLock.appGroup
        ) else {
            return nil
        }
        let descriptor = open(
            container.appendingPathComponent(fileName).path,
            O_CREAT | O_RDWR,
            S_IRUSR | S_IWUSR
        )
        guard descriptor >= 0 else {
            return nil
        }

        let deadline = Date().addingTimeInterval(timeout)
        while flock(descriptor, LOCK_EX | LOCK_NB) != 0 {
            if Date() >= deadline {
                close(descriptor)
                return nil
            }
            usleep(50_000)
        }
        return descriptor
    }

    static func release(_ descriptor: Int32) {
        flock(descriptor, LOCK_UN)
        close(descriptor)
    }
}

enum WidgetTokenVault {
    static let service = "org.sparcs.otlplus.token-vault"
    static let account = "token-pair"
    static let accessGroup = "N5V8W52U3U.org.sparcs.otlplus.token-vault"

    static func readMigratingLegacy(from defaults: UserDefaults?) throws -> WidgetTokenPair? {
        try WidgetTokenVaultLock.withLock {
            if let pair = try readUnlocked() {
                removeLegacyTokens(from: defaults)
                return pair
            }

            let accessToken = defaults?.string(forKey: "accessToken")
            let refreshToken = defaults?.string(forKey: "refreshToken")
            guard
                let accessToken = accessToken,
                !accessToken.isEmpty,
                let refreshToken = refreshToken,
                !refreshToken.isEmpty
            else {
                removeLegacyTokens(from: defaults)
                return nil
            }

            let pair = WidgetTokenPair(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
            try writeUnlocked(pair)
            removeLegacyTokens(from: defaults)
            return pair
        }
    }

    static func read() throws -> WidgetTokenPair? {
        try WidgetTokenVaultLock.withLock(readUnlocked)
    }

    static func writeIfRefreshTokenMatches(
        expectedRefreshToken: String,
        pair: WidgetTokenPair
    ) throws -> Bool {
        try WidgetTokenVaultLock.withLock {
            guard try readUnlocked()?.refreshToken == expectedRefreshToken else {
                return false
            }
            try writeUnlocked(pair)
            return true
        }
    }

    static func clearIfRefreshTokenMatches(
        _ expectedRefreshToken: String
    ) throws -> Bool {
        try WidgetTokenVaultLock.withLock {
            guard try readUnlocked()?.refreshToken == expectedRefreshToken else {
                return false
            }
            try clearUnlocked()
            return true
        }
    }

    private static func readUnlocked() throws -> WidgetTokenPair? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess, let data = result as? Data else {
            throw WidgetTokenVaultError.keychain(status)
        }

        let pair = try JSONDecoder().decode(WidgetTokenPair.self, from: data)
        guard pair.isValid else {
            throw WidgetTokenVaultError.invalidTokenPair
        }
        return pair
    }

    private static func writeUnlocked(_ pair: WidgetTokenPair) throws {
        guard pair.isValid else {
            throw WidgetTokenVaultError.invalidTokenPair
        }

        let data = try JSONEncoder().encode(pair)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw WidgetTokenVaultError.keychain(updateStatus)
        }

        var item = baseQuery
        attributes.forEach { item[$0.key] = $0.value }
        let addStatus = SecItemAdd(item as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }
        if addStatus == errSecDuplicateItem {
            let retryStatus = SecItemUpdate(
                baseQuery as CFDictionary,
                attributes as CFDictionary
            )
            guard retryStatus == errSecSuccess else {
                throw WidgetTokenVaultError.keychain(retryStatus)
            }
            return
        }
        throw WidgetTokenVaultError.keychain(addStatus)
    }

    private static func clearUnlocked() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw WidgetTokenVaultError.keychain(status)
        }
    }

    private static func removeLegacyTokens(from defaults: UserDefaults?) {
        defaults?.removeObject(forKey: "accessToken")
        defaults?.removeObject(forKey: "refreshToken")
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessGroup as String: accessGroup,
        ]
    }
}

struct Provider: IntentTimelineProvider {
    typealias Entry = WidgetEntry
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), timetableData: nil, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let sharedDefaults = UserDefaults.init(suiteName: "group.org.sparcs.otl")
        let tokenPair: WidgetTokenPair?
        do {
            tokenPair = try WidgetTokenVault.readMigratingLegacy(from: sharedDefaults)
        } catch {
            tokenPair = nil
        }
        guard let tokenPair = tokenPair else {
            completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
            return
        }

        let API: OTLAPI = OTLAPI.shared
        API.setTokens(
            accessToken: tokenPair.accessToken,
            refreshToken: tokenPair.refreshToken
        )
        
        API.getCurrentSemester() { result in
            switch result {
            case .success(let semester):
                // 1. Fetch all timetables summary to update the list in IntentHandler
                API.getTimetables(year: semester.year, semester: semester.semester) { result in
                    if case .success(let summaries) = result {
                        let encoder = JSONEncoder()
                        if let data = try? encoder.encode(summaries) {
                            sharedDefaults?.set(data, forKey: "timetableSummaries")
                        }
                    }
                    
                    // 2. Fetch the specific selected timetable
                    let identifier = configuration.nextClassTimetable?.identifier ?? "0"
                    let completionWithData: (Result<Timetable, Error>) -> Void = { result in
                        switch result {
                        case .success(let timetable):
                            let timetables = [timetable]
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .withoutEscapingSlashes
                            do {
                                let data = try encoder.encode(timetables)
                                sharedDefaults?.set(String(data: data, encoding: .utf8), forKey: "timetables")
                            } catch {
                                print(error)
                            }
                            let entryDate = Date()
                            let entry = WidgetEntry(date: entryDate, timetableData: timetables, configuration: configuration)
                            completion(entry)
                        case .failure(_):
                            completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
                        }
                    }
                    
                    if identifier == "0" {
                        API.getMyTimetable(year: semester.year, semester: semester.semester, completion: completionWithData)
                    } else if let timetableId = Int(identifier) {
                        API.getTimetable(timetableId: timetableId, completion: completionWithData)
                    } else {
                        API.getMyTimetable(year: semester.year, semester: semester.semester, completion: completionWithData)
                    }
                }
            case .failure(_):
                let decoder = JSONDecoder()
                do {
                    let data = try decoder.decode([Timetable].self, from: (sharedDefaults?.string(forKey: "timetables")?.data(using: .utf8)) ?? Data())
                    completion(WidgetEntry(date: Date(), timetableData: data, configuration: configuration))
                } catch {
                    completion(WidgetEntry(date: Date(), timetableData: nil, configuration: configuration))
                }
            }
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        var entries: [WidgetEntry] = [WidgetEntry]()
        let sharedDefaults = UserDefaults.init(suiteName: "group.org.sparcs.otl")
        let tokenPair: WidgetTokenPair?
        var tokenVaultUnavailable = false
        do {
            tokenPair = try WidgetTokenVault.readMigratingLegacy(from: sharedDefaults)
        } catch {
            tokenPair = nil
            tokenVaultUnavailable = true
        }
        guard let tokenPair = tokenPair else {
            let currentDate = Date()
            entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
            let policy: TimelineReloadPolicy = tokenVaultUnavailable
                ? .after(currentDate.addingTimeInterval(5 * 60))
                : .never
            completion(Timeline(entries: entries, policy: policy))
            return
        }

        let API: OTLAPI = OTLAPI.shared
        API.setTokens(
            accessToken: tokenPair.accessToken,
            refreshToken: tokenPair.refreshToken
        )
        
        API.getCurrentSemester() { result in
            switch result {
            case .success(let currentSemester):
                // 1. Fetch all timetables summary to update the list in IntentHandler
                API.getTimetables(year: currentSemester.year, semester: currentSemester.semester) { result in
                    if case .success(let summaries) = result {
                        let encoder = JSONEncoder()
                        if let data = try? encoder.encode(summaries) {
                            sharedDefaults?.set(data, forKey: "timetableSummaries")
                        }
                    }
                    
                    // 2. Fetch the specific selected timetable
                    let identifier = configuration.nextClassTimetable?.identifier ?? "0"
                    let completionWithData: (Result<Timetable, Error>) -> Void = { result in
                        switch result {
                        case .success(let timetable):
                            let timetables = [timetable]
                            let encoder = JSONEncoder()
                            encoder.outputFormatting = .withoutEscapingSlashes
                            do {
                                let data = try encoder.encode(timetables)
                                sharedDefaults?.set(String(data: data, encoding: .utf8), forKey: "timetables")
                            } catch {
                                print(error)
                            }
                            
                            let currentDate = Date()
                            for minutesOffset in 0..<5 {
                                let entryDate = Calendar.current.date(byAdding: .minute, value: minutesOffset*12, to: currentDate)!
                                let entry = WidgetEntry(date: entryDate, timetableData: timetables, configuration: configuration)
                                entries.append(entry)
                            }
                            
                            let timeline = Timeline(entries: entries, policy: .atEnd)
                            completion(timeline)
                        case .failure(_):
                            let currentDate = Date()
                            entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
                            let timeline = Timeline(entries: entries, policy: .never)
                            completion(timeline)
                        }
                    }

                    if identifier == "0" {
                        API.getMyTimetable(year: currentSemester.year, semester: currentSemester.semester, completion: completionWithData)
                    } else if let timetableId = Int(identifier) {
                        API.getTimetable(timetableId: timetableId, completion: completionWithData)
                    } else {
                        API.getMyTimetable(year: currentSemester.year, semester: currentSemester.semester, completion: completionWithData)
                    }
                }
            case .failure(_):
                let decoder = JSONDecoder()
                do {
                    let data = try decoder.decode([Timetable].self, from: (sharedDefaults?.string(forKey: "timetables")?.data(using: .utf8)) ?? Data())
                    
                    let currentDate = Date()
                    for minutesOffset in 0..<5 {
                        let entryDate = Calendar.current.date(byAdding: .minute, value: minutesOffset*12, to: currentDate)!
                        let entry = WidgetEntry(date: entryDate, timetableData: data, configuration: configuration)
                        entries.append(entry)
                    }
                    
                    let timeline = Timeline(entries: entries, policy: .atEnd)
                    completion(timeline)
                } catch {
                    let currentDate = Date()
                    entries = [WidgetEntry(date: currentDate, timetableData: nil, configuration: configuration)]
                    
                    let timeline = Timeline(entries: entries, policy: .never)
                    completion(timeline)
                }
            }
        }
        
        
    }
}



struct WidgetEntry: TimelineEntry {
    let date: Date
    let timetableData: [Timetable]?
    let configuration: ConfigurationIntent
}


@main
struct OTLWidgetBundle : WidgetBundle {
    var body: some Widget {
        // Non-interactive widgets for iOS 15+
        NextClassWidget()
        TodayClassesWidget()
        WeekClassesWidget()
        
        // Lock Complications accessories for iOS 16+
        if #available(iOS 16.1, *) {
            NextClassAccessory()
            TimeInlineAccessory()
            LocationInlineAccessory()
        }
    }
}
