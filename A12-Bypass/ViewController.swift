//
//  ViewController.swift
//  A12-Bypass
//
//  Created by Pruebas on 09/12/24.
//

import Cocoa

class ViewController: NSViewController {
  
    var MinaRemoteClass: DeviceNotificationHandler?

  
    func initializeDeviceNotificationHandler() {
        MinaRemoteClass = MinaRemoteClassImplementation() // Asigna la instancia de tu clase que maneja las notificaciones

        var notificationReference: UnsafeMutableRawPointer? = nil

        // Diccionario de opciones
        let options: [String: Any] = [
            "NotificationOptionSearchForPairedDevices": 1,
            "NotificationOptionSearchForWiFiPairableDevices": 0
        ]

        // Convertir el diccionario a CFDictionary
        let cfOptions = options as NSDictionary as CFDictionary

        // Verifica que `AMDeviceNotificationSubscribeWithOptions` está correctamente definido
        let result = AMDeviceNotificationSubscribeWithOptions(
            { (deviceList, cookie) in
                guard let deviceList = deviceList else {
                    print("Device list is nil.")
                    return
                }
                let handler = MinaRemoteClassImplementation()
                handler.deviceNotificationReceivedWithInfo(deviceList)
            },
            0, 0, 0,
            &notificationReference,
            cfOptions as? [AnyHashable : Any]
        )

        // Verifica el resultado de la suscripción
        if result != MDERR_OK {
            print("Failed to subscribe to device notifications with error: \(result)")
        } else {
            print("Successfully subscribed to device notifications.")
        }
    }

    func runShellCommand(_ command: String) -> String? {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            print("Error al ejecutar el comando: \(error)")
            return nil
        }

        process.waitUntilExit()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        let ou = String(data: outputData, encoding: .utf8)
        print(ou as Any)
        return String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func createDirectoryIfNotExists(at path: String) {
        let fileManager = FileManager.default
        let url = URL(fileURLWithPath: path)

        if !fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                print("Directorio creado en \(path)")
            } catch {
                print("Error al crear el directorio: \(error)")
            }
        } else {
            print("El directorio ya existe en \(path)")
        }
    }
    
    
    func cD()->String{
        return Bundle.main.resourcePath!
    }
    
    func DeviceInfo(_ infos:String)->String{
        return runShellCommand(cD() + "/ideviceinfo -k " + infos)!.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeDeviceNotificationHandler()
        let User = runShellCommand("echo \"/Users/$(whoami)\" | sed 's/ /\\ /g'")
        createDirectoryIfNotExists(at: User! + "/Desktop/" + DeviceInfo("UniqueDeviceID"))
        let sourceFilePath = URL(fileURLWithPath: "/Library/Caches/com.apple.MobileGestalt.plist")

        let destinationPath = URL(fileURLWithPath: "/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches/com.apple.MobileGestalt.plist")

        let fileToRestore = FileToRestore(from: sourceFilePath, to: destinationPath, owner: 501, group: 501)
        
        let backup = Restore.createMobileGestalt(file: fileToRestore)

        do {
            let backupDirectory = URL(fileURLWithPath: User! + "/Desktop/" + DeviceInfo("UniqueDeviceID"))
            
            try backup.writeTo(directory: backupDirectory)
            
            print("Backup creado exitosamente en \(backupDirectory.path)")
            _ = runShellCommand(cD() + "/idevicebackup2 -d --full restore --system --settings --reboot " + User! + "/Desktop")!
        } catch {
            print("Error al escribir el backup: \(error)")
        }
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

}


extension Dictionary where Key == String, Value == Any {
    func withCFDictionary<T>(_ body: (CFDictionary) -> T) -> T {
        let cfDict = self as NSDictionary
        return body(cfDict)
    }
}

func DeviceNotificationReceived(deviceList: UnsafeMutableRawPointer?, cookie: Int32) {
    guard let deviceList = deviceList else {
        print("Device list is nil.")
        return
    }
    var MinaRemoteClass: DeviceNotificationHandler?
    let deviceListRef = UnsafeMutablePointer<AMDeviceList>(OpaquePointer(deviceList))
    MinaRemoteClass = MinaRemoteClassImplementation()
    if let handler = MinaRemoteClass {
        handler.deviceNotificationReceivedWithInfo(deviceListRef)
    } else {
        print("MinaRemoteClass is not set or does not implement DeviceNotificationHandler.")
    }
}
