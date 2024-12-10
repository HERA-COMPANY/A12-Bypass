import NIO

struct MBDBRecord {
    var domain: String
    var filename: String
    var link: String
    var hash: Data
    var key: Data
    var mode: UInt16
    var inode: UInt64
    var user_id: Int32
    var group_id: Int32
    var mtime: UInt32
    var atime: UInt32
    var ctime: UInt32
    var size: UInt64
    var flags: UInt8
    var properties: [String: String]

    // Inicialización desde un buffer
    init(buffer: inout ByteBuffer) throws {
        domain = try buffer.readPrefixedString()
        filename = try buffer.readPrefixedString()
        link = try buffer.readPrefixedString()
        hash = try buffer.readPrefixedData()
        key = try buffer.readPrefixedData()
        mode = try buffer.readIntegerOrThrow(as: UInt16.self)
        inode = try buffer.readIntegerOrThrow(as: UInt64.self)
        user_id = try buffer.readIntegerOrThrow(as: Int32.self)
        group_id = try buffer.readIntegerOrThrow(as: Int32.self)
        mtime = try buffer.readIntegerOrThrow(as: UInt32.self)
        atime = try buffer.readIntegerOrThrow(as: UInt32.self)
        ctime = try buffer.readIntegerOrThrow(as: UInt32.self)
        size = try buffer.readIntegerOrThrow(as: UInt64.self)
        flags = try buffer.readIntegerOrThrow(as: UInt8.self)

        // Leer propiedades
        properties = [:]
        let propertiesCount = try buffer.readIntegerOrThrow(as: UInt8.self)
        for _ in 0..<propertiesCount {
            let name = try buffer.readPrefixedString()
            let value = try buffer.readPrefixedString()
            properties[name] = value
        }
    }
    
    init(domain: String,
          filename: String,
          link: String,
          hash: Data,
          key: Data,
          mode: UInt16,
          inode: UInt64,
          user_id: Int32,
          group_id: Int32,
          mtime: UInt32,
          atime: UInt32,
          ctime: UInt32,
          size: UInt64,
          flags: UInt8,
          properties: [String: String]) {
         
         self.domain = domain
         self.filename = filename
         self.link = link
         self.hash = hash
         self.key = key
         self.mode = mode
         self.inode = inode
         self.user_id = user_id
         self.group_id = group_id
         self.mtime = mtime
         self.atime = atime
         self.ctime = ctime
         self.size = size
         self.flags = flags
         self.properties = properties
     }

    // Convertir a `Data`
    func toData() -> Data {
        var buffer = ByteBufferAllocator().buffer(capacity: calculateCapacity())
        buffer.writePrefixedString(domain)
        buffer.writePrefixedString(filename)
        buffer.writePrefixedString(link)
        buffer.writePrefixedData(hash)
        buffer.writePrefixedData(key)
        buffer.writeInteger(mode, endianness: .big)
        buffer.writeInteger(inode, endianness: .big)
        buffer.writeInteger(user_id, endianness: .big)
        buffer.writeInteger(group_id, endianness: .big)
        buffer.writeInteger(mtime, endianness: .big)
        buffer.writeInteger(atime, endianness: .big)
        buffer.writeInteger(ctime, endianness: .big)
        buffer.writeInteger(size, endianness: .big)
        buffer.writeInteger(flags, endianness: .big)

        buffer.writeInteger(UInt8(properties.count), endianness: .big)
        for (name, value) in properties {
            buffer.writePrefixedString(name)
            buffer.writePrefixedString(value)
        }

        return Data(buffer.readableBytesView)
    }

    private func calculateCapacity() -> Int {
        var capacity = 2 * 5 + domain.count + filename.count + link.count + hash.count + key.count
        capacity += 2 + 8 + 4 * 5 + 8 + 1 + 1
        for (name, value) in properties {
            capacity += 2 * 2 + name.count + value.count
        }
        return capacity
    }
}

extension ByteBuffer {
    mutating func readPrefixedString() throws -> String {
        guard let length = self.readInteger(endianness: .big, as: UInt16.self) else {
            throw DeserializationError.invalidLength
        }
        if length == 0xffff { return "" }
        guard let string = self.readString(length: Int(length)) else {
            throw DeserializationError.invalidData
        }
        return string
    }

    mutating func readPrefixedData() throws -> Data {
        guard let length = self.readInteger(endianness: .big, as: UInt16.self) else {
            throw DeserializationError.invalidLength
        }
        if length == 0xffff { return Data() }
        guard let bytes = self.readBytes(length: Int(length)) else {
            throw DeserializationError.invalidData
        }
        return Data(bytes)
    }

    mutating func readIntegerOrThrow<T: FixedWidthInteger>(as type: T.Type) throws -> T {
        guard let value = self.readInteger(endianness: .big, as: type) else {
            throw DeserializationError.invalidData
        }
        return value
    }

    mutating func writePrefixedString(_ string: String) {
        let data = string.data(using: .utf8)!
        self.writeInteger(UInt16(data.count), endianness: .big, as: UInt16.self)
        self.writeBytes(data)
    }

    mutating func writePrefixedData(_ data: Data) {
        self.writeInteger(UInt16(data.count), endianness: .big, as: UInt16.self)
        self.writeBytes(data)
    }
}

struct MobileBackupDatabase {
    let magic = "mbdb"
    let version: [UInt8] = [0x05, 0x00];
    var records: [MBDBRecord]
    
    init(data: Data) {
        var buffer = ByteBuffer(bytes: data)
        if let dataMagic = buffer.readString(length: 4) {
            if dataMagic != magic {
                fatalError("Wrong magic")
            }
        } else {
            fatalError("Can't parse magic")
        }
        if let dataVersion = buffer.readInteger(endianness: .big, as: UInt16.self) {
            print("Version: \(dataVersion)")
        } else {
            fatalError("Can't parse version")
        }
        
        records = [MBDBRecord]()
        while buffer.readableBytes > 0 {
            do {
                let record = try MBDBRecord(buffer: &buffer)
                records.append(record)
            } catch {
                print("Error al procesar MBDBRecord: \(error)")
                break
            }
        }
    }
    
    init(records: [MBDBRecord]) {
        self.records = records
    }
    
    func toData() -> Data {
        var result = NSMutableData()
        result.append(Data(magic.utf8))
        result.append(version, length: version.count)
        for record in records {
            result.append(record.toData())
        }
        return result as Data
    }
}

enum DeserializationError: Error {
    case invalidLength
    case invalidData
}
