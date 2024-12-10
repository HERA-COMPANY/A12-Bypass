//
//  ExternalDeclarations.h
//  mobdevim
//
//  Created by Derek Selander
//  Copyright © 2017 Selander. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef ExternalDeclarations_h
#define ExternalDeclarations_h

#define MDERR_OK                ERR_SUCCESS
#define MDERR_SYSCALL           (ERR_MOBILE_DEVICE | 0x01)
#define MDERR_OUT_OF_MEMORY     (ERR_MOBILE_DEVICE | 0x03)
#define MDERR_QUERY_FAILED      (ERR_MOBILE_DEVICE | 0x04)
#define MDERR_INVALID_ARGUMENT  (ERR_MOBILE_DEVICE | 0x0b)
#define MDERR_DICT_NOT_LOADED   (ERR_MOBILE_DEVICE | 0x25)

#define ADNCI_MSG_CONNECTED     1
#define ADNCI_MSG_DISCONNECTED  2
#define ADNCI_MSG_UNKNOWN       3

typedef struct _AMDevice {
    void *unknown0[4];
    CFStringRef deviceID;
    int32_t connection_type;
    int32_t unknown44;
    void *lockdown_conn;
    CFStringRef session;
    pthread_mutex_t mutex_lock;
    CFStringRef service_name;
    int32_t interface_index;
    int8_t device_active;
    unsigned char unknown7[3];
    int64_t unknown8;
    CFDataRef unknownData;
    CFDataRef network_address;
} AMDevice;

#ifndef AMDeviceList_h
#define AMDeviceList_h


typedef struct {
    int status; // Estado del dispositivo (conectado o desconectado)
    CFDictionaryRef connectionDeets; // Detalles de conexión (USB, etc.)
    void *device; // Puntero al dispositivo
} AMDeviceList;

#endif /* AMDeviceList_h */


#pragma mark - typedef
typedef AMDevice *AMDeviceRef;
typedef struct _AMDServiceConnection {} AMDServiceConnection;
typedef struct AMDServiceConnection *AMDServiceConnectionRef;
typedef struct _AFCConnection  {} AFCConnection;
typedef AFCConnection *AFCConnectionRef;

typedef enum : int {
    DeviceConnectionStatusConnect = 1,
    DeviceConnectionStatusDisconnected = 2,
    DeviceConnectionStatusUnsubscribed = 3,
} DeviceConnectionStatus;



typedef struct AMDeviceCallBackDevice {
    AMDeviceRef device;
    DeviceConnectionStatus status;
    int dunno1;
    void *dunno2;
    int dunno[4];
    
    CFDictionaryRef connectionDeets;
} AMDeviceCallBackDevice;
//typedef AMDeviceList *AMDeviceListRef;
/*
typedef struct _AMDeviceList {
    AMDeviceRef device;
    DeviceConnectionStatus status;
    int dunno1;
    void *dunno2;
    int dunno[4];
    
    NSDictionary *connectionDeets;
} AMDeviceList;*/

typedef AMDeviceList *AMDeviceListRef;


typedef struct _AFCIterator {
    char boring[0x10];
    CFDictionaryRef fileAttributes;
} AFCIterator;
typedef AFCIterator *AFCIteratorRef;

typedef struct _AFCFileInfo {} AFCFileInfo;
typedef AFCFileInfo *AFCFileInfoRef;

typedef struct _AFCFileDescriptor {
    char boring[0x24];
    char *path;
} AFCFileDescriptor;
typedef AFCFileDescriptor *AFCFileDescriptorRef;





//*****************************************************************************/
#pragma mark - AFC.* Functions, File Coordinator logic (I/O)
//*****************************************************************************/

// file i/o functions (thank you Samantha Marshall for these)
mach_error_t AFCFileRefOpen(AFCConnectionRef, const char *path, uint64_t mode,AFCFileDescriptorRef*);
mach_error_t AFCFileRefClose(AFCConnectionRef, AFCFileDescriptorRef);
mach_error_t AFCFileRefSeek(AFCConnectionRef,  AFCFileDescriptorRef, int64_t offset, uint64_t mode);
mach_error_t AFCFileRefTell(AFCConnectionRef, AFCFileDescriptorRef, uint64_t *offset);
size_t AFCFileRefRead(AFCConnectionRef,AFCFileDescriptorRef,void **buf,size_t *len);
mach_error_t AFCFileRefSetFileSize(AFCConnectionRef,AFCFileDescriptorRef, uint64_t offset);
mach_error_t AFCFileRefWrite(AFCConnectionRef,AFCFileDescriptorRef ref, const void *buf, uint32_t len);

mach_error_t AFCDirectoryOpen(AFCConnectionRef, const char *, AFCIteratorRef*);
mach_error_t AFCDirectoryRead(AFCConnectionRef, AFCIteratorRef, void *);
mach_error_t AFCDirectoryClose(AFCConnectionRef, AFCIteratorRef);
mach_error_t AFCDirectoryCreate(AFCConnectionRef, const char *);
mach_error_t AFCRemovePath(AFCConnectionRef, const char *);
mach_error_t AFCRenamePath(AFCConnectionRef conn, const char *from, const char *to);

mach_error_t AFCFileInfoOpen(AFCConnectionRef, const char *, AFCIteratorRef*);
mach_error_t AFCKeyValueRead(AFCIteratorRef,  char **key,  char **val);
mach_error_t AFCKeyValueClose(AFCIteratorRef);


mach_error_t AMDeviceNotificationSubscribe(void (*)(AMDeviceCallBackDevice, int), int, int, int, void *);
mach_error_t AMDeviceNotificationSubscribeWithOptions(void (*)(AMDeviceListRef, int), int, int, int, void *, NSDictionary *);
mach_error_t AMDeviceConnect(AMDeviceRef);
mach_error_t AMDeviceDisconnect(AMDeviceRef);
bool AMDeviceIsPaired(AMDeviceRef);
mach_error_t AMDevicePair(AMDeviceRef);
mach_error_t AMDeviceValidatePairing(AMDeviceRef);
mach_error_t AMDeviceStartSession(AMDeviceRef);
mach_error_t AMDeviceStopSession(AMDeviceRef);
mach_error_t AMDeviceNotificationUnsubscribe(AMDeviceCallBackDevice*);
id AMDServiceConnectionGetSecureIOContext(AMDServiceConnectionRef);

mach_error_t AMDeviceSecureTransferPath(int, AMDeviceRef, NSURL*, NSDictionary *, void *, int);
mach_error_t AMDeviceSecureInstallApplication(int, AMDeviceRef, NSURL*, NSDictionary*, void *, int);
mach_error_t AMDeviceSecureUninstallApplication(AMDServiceConnectionRef connection, void * dunno, NSString *bundleIdentifier, NSDictionary *params, void (*installCallback)(NSDictionary*, void *));
mach_error_t AMDeviceSecureInstallApplicationBundle(AMDeviceRef, NSURL *path, NSDictionary *params, void (*installCallback)(NSDictionary*, void *));

mach_error_t AMDeviceStartHouseArrestService(AMDeviceRef, id, id, int *, void *);

mach_error_t AMDeviceLookupApplications(AMDeviceRef, id, NSDictionary **);
mach_error_t AMDeviceSecureStartService(AMDeviceRef, NSString *, NSDictionary *, void *);
mach_error_t AMDeviceStartServiceWithOptions(AMDeviceRef, NSString *, NSDictionary *, int *socket);
mach_error_t AMDeviceSecureArchiveApplication(AMDServiceConnectionRef, AMDeviceRef, NSString *, NSDictionary *, void * /* */, id);
mach_error_t AMDeviceGetTypeID(AMDeviceRef);
AMDeviceRef AMDeviceCreateCopy(AMDeviceRef);

CFTypeRef AMDeviceCreateActivationSessionInfo(AMDeviceRef device, mach_error_t * result);
CFTypeRef AMDeviceCreateActivationInfoWithOptions(AMDeviceRef device, CFPropertyListRef response, CFDictionaryRef Options, mach_error_t *err);


mach_error_t AMDeviceActivateWithOptions(AMDeviceRef device, CFDataRef record, CFDictionaryRef Options);
mach_error_t AMDeviceActivate(AMDeviceRef device, CFMutableDictionaryRef);
mach_error_t AMDeviceDeactivate(AMDeviceRef device);

// device/file information functions
//afc_error_t AFCDeviceInfoOpen(afc_connection conn, afc_dictionary *info);

mach_error_t AMDeviceSecureRemoveApplicationArchive(AMDServiceConnectionRef, AMDeviceRef, NSString *, void *, void *, void *);
mach_error_t AFCConnectionOpen(AMDServiceConnectionRef, int, AFCConnectionRef * /*AFCConnection */);


mach_error_t AFCConnectionClose(AFCConnectionRef);
mach_error_t AMDServiceConnectionSendMessage(AMDServiceConnectionRef serviceConnection, CFPropertyListRef message, CFPropertyListFormat format);

mach_error_t AMDServiceConnectionSend(AMDServiceConnectionRef, void *content, size_t length);
NSArray* AMDCreateDeviceList(void);
NSString *AMDeviceGetName(AMDeviceRef);
int AMDServiceConnectionGetSocket(AMDServiceConnectionRef);
long AMDServiceConnectionReceive(AMDServiceConnectionRef, void *, long);
mach_error_t AMDServiceConnectionReceiveMessage(AMDServiceConnectionRef serviceConnection, CFPropertyListRef, CFPropertyListFormat*);
void AMDServiceConnectionInvalidate(AMDServiceConnectionRef);
id _AMDeviceCopyInstalledAppInfo(AMDeviceRef, char *);
CFTypeRef AMDeviceCopyValue(AMDeviceRef, CFStringRef, CFStringRef);
CFStringRef AMDeviceSetValue(AMDeviceRef device, CFStringRef domain, CFStringRef key, CFTypeRef value);
NSString *AMDeviceCopyDeviceIdentifier(AMDeviceRef);
void *AMDeviceCopyDeviceLocation(AMDeviceRef);
NSDictionary* MISProfileCopyPayload(id);
NSArray *AMDeviceCopyProvisioningProfiles(AMDeviceRef);
mach_error_t AMDeviceEnterRecovery(AMDeviceRef device);
AFCConnectionRef AFCConnectionCreate(int unknown, int socket, int unknown2, int unknown3, void *context);


/// Queries information about the device see below for examples
extern id AMDeviceCopyValueWithError(AMDeviceRef ref, NSString * domain, NSString * value, NSError **err);

/* AMDeviceCopyValueWithError (domain, values) examples
 ChipID / 32734
 DeviceName / Bobs’s iPhone
 UniqueChipID  / 1410439760381222
 InternationalMobileEquipmentIdentity / 289162076560126
 ActivationState / Activated
 DeviceClass / iPhone
 WiFiAddress / cc:08:8d:c7:04:6d
 BuildVersion /  15B150
 BluetoothAddress / cc:08:8d:c7:0d:b2
 HardwareModel / D10AP
 ProductVersion / 11.1.1
 SerialNumber / NNPSFCHNHG7A
 DeviceColor / 1
 DeviceEnclosureColor / 5
 CPUArchitecture / arm64
 com.apple.disk_usage, TotalDataCapacity / 252579303424
 ApNonce / <63af9d29 2a44cdac 00766d66 84a2c244 3740d4d4 bd494ec8 dd3d9ad0 9e2b5668>
 HasSEP / 1
 SEPNonce /  <00766d66 00766d66 00766d66 a21b8ab2 2576648c>
 Image4CryptoHashMethod / sha2-384
 Image4Supported / 1
 CertificateSecurityMode / 1
 EffectiveSecurityModeAp / 1
 EffectiveProductionStatusAp / 1
 FirmwarePreflightInfo / 2017-11-28 02:10:43.983085-0700 mobdevim[12621:1854164] {
 CertID = 2315222105;
 ChipID = 9781473;
 ChipSerialNo = <fee5c8c3>;
 FusingStatus = 3;
 SKeyStatus = 0;
 VendorID = 3;
 }
 
 BasebandGoldCertId / 2315222105
 
 BasebandKeyHashInformation /     AKeyStatus = 2;
 SKeyStatus = 0;
 PhoneNumber / (555) 632-1424
 RegionInfo / LL/A
 SIMStatus / kCTSIMSupportSIMStatusReady
 }
 
 com.apple.mobile.wireless_lockdown, BonjourFullServiceName / cc:08:8d:c7:04:6d@fe80::ce08:8dff:fec7:46d._apple-mobdev2._tcp.local.
 
 com.apple.mobile.wireless_lockdown, SupportsWifiSyncing / (null)
 
 com.apple.mobile.wireless_lockdown, WirelessBuddyID / (null)
 
 DevicePublicKey / bigcert
 DeviceCertificate / bigcert
 
 TelephonyCapability / 1
 BasebandStatus / BBInfoAvailable
 
 com.apple.disk_usage, AmountDataAvailable / 184877105152
 
 com.apple.mobile.internal, DevToolsAvailable / Standard
 
 PasswordProtected / 1
 
 ProductionSOC / 1
 
 com.apple.mobile.ldwatch, WatchCompanionCapability / 1
 
 SupportedDeviceFamilies ( 1 )
 
 com.apple.mobile.battery, BatteryCurrentCapacity / 100
 */

#endif /* ExternalDeclarations_h */
