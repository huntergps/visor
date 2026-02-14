import ExternalAccessory
import Flutter

/// Zebra printer manager using ExternalAccessory framework (Bluetooth Classic/MFi).
/// Zebra printers are MFi certified and use the "com.zebra.rawport" protocol
/// for data communication over Bluetooth Classic on iOS.
///
/// NOTE: The printer must be paired in iOS Settings > Bluetooth before it can be used.
class ZebraPrinterManager: NSObject, StreamDelegate {

    private var session: EASession?
    private var connectedAccessory: EAAccessory?

    private static let zebraProtocol = "com.zebra.rawport"

    private func log(_ msg: String) {
        NSLog("ZebraBT: \(msg)")
        print("ZebraBT: \(msg)")
    }

    // MARK: - Public API (mirrors Android MethodChannel contract)

    /// Returns list of paired Zebra printers (MFi accessories with com.zebra.rawport).
    /// The printer must be paired in iOS Settings > Bluetooth first.
    func getPairedDevices(result: @escaping FlutterResult) {
        let accessories = EAAccessoryManager.shared().connectedAccessories
        log("getPairedDevices: \(accessories.count) total connected accessories")

        var devices: [[String: String]] = []
        for acc in accessories {
            log("  accessory: '\(acc.name)' serial=\(acc.serialNumber) protocols=\(acc.protocolStrings)")
            if acc.protocolStrings.contains(ZebraPrinterManager.zebraProtocol) {
                devices.append([
                    "name": acc.name.isEmpty ? acc.serialNumber : acc.name,
                    "address": acc.serialNumber,
                ])
            }
        }

        log("getPairedDevices: \(devices.count) Zebra printers found")
        result(devices)
    }

    /// Connect to a Zebra printer by serial number.
    func connect(address: String, result: @escaping FlutterResult) {
        // Close any existing session
        disconnectInternal()

        let accessories = EAAccessoryManager.shared().connectedAccessories
        guard let target = accessories.first(where: {
            $0.serialNumber == address &&
            $0.protocolStrings.contains(ZebraPrinterManager.zebraProtocol)
        }) else {
            log("connect: printer '\(address)' not found among \(accessories.count) accessories")
            result(FlutterError(
                code: "BT_CONNECT_FAIL",
                message: "Impresora no encontrada. Verifica que esté emparejada en Ajustes > Bluetooth.",
                details: nil
            ))
            return
        }

        guard let newSession = EASession(accessory: target, forProtocol: ZebraPrinterManager.zebraProtocol) else {
            log("connect: failed to create EASession with '\(target.name)'")
            result(FlutterError(
                code: "BT_CONNECT_FAIL",
                message: "No se pudo abrir sesión con la impresora. Intenta apagar y encender la impresora.",
                details: nil
            ))
            return
        }

        session = newSession
        connectedAccessory = target

        // Configure output stream
        newSession.outputStream?.delegate = self
        newSession.outputStream?.schedule(in: .current, forMode: .default)
        newSession.outputStream?.open()

        // Configure input stream (needed for bidirectional comms)
        newSession.inputStream?.delegate = self
        newSession.inputStream?.schedule(in: .current, forMode: .default)
        newSession.inputStream?.open()

        log("connect: session opened with '\(target.name)' (serial: \(target.serialNumber))")
        result(true)
    }

    /// Send string data (ZPL) to the connected printer.
    func send(data: String, result: @escaping FlutterResult) {
        guard let outputStream = session?.outputStream else {
            result(FlutterError(
                code: "BT_NOT_CONNECTED",
                message: "Sin conexión a impresora",
                details: nil
            ))
            return
        }

        guard let encoded = data.data(using: .utf8) else {
            result(FlutterError(
                code: "BT_SEND_FAIL",
                message: "Error codificando datos",
                details: nil
            ))
            return
        }

        log("send: \(encoded.count) bytes to \(connectedAccessory?.name ?? "?")")

        let bytes = [UInt8](encoded)
        var offset = 0
        var retryCount = 0
        let maxRetries = 50 // avoid infinite loop if stream never has space

        while offset < bytes.count && retryCount < maxRetries {
            let chunkSize = min(1024, bytes.count - offset)
            let chunk = Array(bytes[offset..<(offset + chunkSize)])
            let bytesWritten = outputStream.write(chunk, maxLength: chunkSize)

            if bytesWritten > 0 {
                offset += bytesWritten
                retryCount = 0
            } else if bytesWritten == 0 {
                // Stream not ready, wait a bit
                retryCount += 1
                Thread.sleep(forTimeInterval: 0.05)
            } else {
                // Error
                log("send: write error at offset \(offset): \(outputStream.streamError?.localizedDescription ?? "unknown")")
                result(FlutterError(
                    code: "BT_SEND_FAIL",
                    message: "Error enviando datos: \(outputStream.streamError?.localizedDescription ?? "desconocido")",
                    details: nil
                ))
                return
            }
        }

        if offset < bytes.count {
            log("send: incomplete, only \(offset)/\(bytes.count) bytes sent")
            result(FlutterError(
                code: "BT_SEND_FAIL",
                message: "Envío incompleto: solo se enviaron \(offset) de \(bytes.count) bytes",
                details: nil
            ))
            return
        }

        log("send: complete, \(bytes.count) bytes sent")
        result(true)
    }

    /// Disconnect from the printer.
    func disconnect(result: @escaping FlutterResult) {
        disconnectInternal()
        result(true)
    }

    private func disconnectInternal() {
        if session != nil {
            session?.inputStream?.close()
            session?.inputStream?.remove(from: .current, forMode: .default)
            session?.outputStream?.close()
            session?.outputStream?.remove(from: .current, forMode: .default)
            session = nil
            connectedAccessory = nil
            log("disconnect: session closed")
        }
    }

    // MARK: - StreamDelegate

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            log("stream: opened")
        case .hasBytesAvailable:
            // Read and discard printer responses
            if let input = aStream as? InputStream {
                var buffer = [UInt8](repeating: 0, count: 1024)
                let bytesRead = input.read(&buffer, maxLength: buffer.count)
                if bytesRead > 0 {
                    let response = String(bytes: buffer[0..<bytesRead], encoding: .utf8) ?? "(binary \(bytesRead)B)"
                    log("stream: received \(bytesRead)B: \(response)")
                }
            }
        case .hasSpaceAvailable:
            break
        case .errorOccurred:
            log("stream: ERROR \(aStream.streamError?.localizedDescription ?? "?")")
        case .endEncountered:
            log("stream: ended")
        default:
            break
        }
    }
}
