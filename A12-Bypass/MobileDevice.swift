import Foundation
import Darwin

var idevice: AMDeviceRef?
var notification: AMDeviceCallBackDevice?
var connection: AMDServiceConnectionRef?
var connected = false

var udidNumber: String?
var serialNumber: String?
var productType: String?
var meid: String?
var imeiNumber: String?
var iosVersion: String?
var simStatus: String?
var chipID: String?

protocol DeviceNotificationHandler {
    func deviceNotificationReceivedWithInfo(_ deviceList: AMDeviceListRef)
}

class MinaRemoteClassImplementation: DeviceNotificationHandler {
    enum DeviceConnectionStatus: Int32 {
        case connected = 0
        case disconnected = 1
        case unknown = 278016
    }
    func deviceNotificationReceivedWithInfo(_ deviceList: AMDeviceListRef) {
        let deviceListPtr = UnsafePointer<AMDeviceList>(OpaquePointer(deviceList))
        
        let rawStatus = deviceListPtr.pointee.status
        print("Raw device status: \(rawStatus)")
        
        // Intenta mapear el estado a la enumeración
        if let deviceStatus = DeviceConnectionStatus(rawValue: rawStatus) {
            switch deviceStatus {
            case .connected:
                print("Dispositivo conectado.")
                handleDeviceConnection(deviceListPtr)
            case .disconnected:
                print("Dispositivo desconectado.")
                idevice = nil
            case .unknown:
                print("Estado desconocido, pero mapeado como 'unknown'.")
            }
        } else {
            print("Estado desconocido del dispositivo. Valor crudo: \(rawStatus)")
        }
    }
    
    private func handleDeviceConnection(_ deviceListPtr: UnsafePointer<AMDeviceList>) {
        guard let unmanagedDetails = deviceListPtr.pointee.connectionDeets else {
            print("Detalles de conexión no disponibles.")
            return
        }
        
        let cfDetails = unmanagedDetails.takeUnretainedValue() as CFDictionary
        guard let connectionDetails = cfDetails as? [String: Any],
              let properties = connectionDetails["Properties"] as? [String: Any],
              let connectionType = properties["ConnectionType"] as? String,
              connectionType == "USB" else {
            print("No se detectó conexión USB.")
            return
        }
        
        print("Conexión USB detectada.")
        if let rawPointer = deviceListPtr.pointee.device {
            idevice = UnsafeMutableRawPointer(rawPointer).assumingMemoryBound(to: AMDevice.self)
            refreshDeviceSession()
            
            if let device = idevice {
                guard let unmanagedValue = AMDeviceCopyValue(device, nil, "UniqueDeviceID" as CFString),
                      let cfValue = unmanagedValue.takeRetainedValue() as? String else {
                    print("No se pudo obtener el UDID.")
                    return
                }
                udidNumber = cfValue
                print("UDID: \(udidNumber!)")
            }
        }
    }
}
func refreshDeviceSession() {
    guard let device = idevice else { return }
    idevice = AMDeviceCreateCopy(device)
    guard AMDeviceConnect(device) == MDERR_OK else {
        print("Error al conectar al dispositivo.")
        return
    }
    if !AMDeviceIsPaired(device) {
        AMDevicePair(device)
    }
    AMDeviceStartSession(device)
}

func getMI() -> String {
    var uuid: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    uuid_generate(&uuid)
    var uuidString = [CChar](repeating: 0, count: 37)
    uuid_unparse_upper(&uuid, &uuidString)
    return String(cString: uuidString)
}
