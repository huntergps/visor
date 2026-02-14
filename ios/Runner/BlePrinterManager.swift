import CoreBluetooth
import Flutter

/// Generic BLE printer manager for iOS.
/// Uses scan-then-connect: when connecting, scans with allowDuplicates to
/// ensure the peripheral is fresh, then connects immediately upon discovery.
class BlePrinterManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var writeCharacteristic: CBCharacteristic?
    private var writeType: CBCharacteristicWriteType = .withResponse

    // Standard BLE services to skip (not printer data)
    private static let skipServices: Set<String> = [
        "1800", "1801", "180A", "180F", "FEF3",
    ]

    // Scan state
    private var discoveredPeripherals: [(peripheral: CBPeripheral, name: String, identifier: String)] = []
    private var scanResult: FlutterResult?
    private var scanTimer: Timer?

    // Connect state
    private var connectResult: FlutterResult?
    private var connectTimer: Timer?
    private var connectTargetUUID: String?
    private var pendingServiceCount = 0
    private var discoveredServiceCount = 0

    // Send state
    private var sendResult: FlutterResult?
    private var pendingWriteCount = 0
    private var totalChunks = 0

    // Disconnect state
    private var disconnectResult: FlutterResult?

    // Flutter channel for logging back to Dart
    var methodChannel: FlutterMethodChannel?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    /// Log to both NSLog and send to Dart via method channel
    private func log(_ msg: String) {
        NSLog("BLE: \(msg)")
        // Also debugPrint to stdout so flutter run captures it
        print("BLE: \(msg)")
    }

    // MARK: - Public API

    func scanForDevices(result: @escaping FlutterResult) {
        guard centralManager.state == .poweredOn else {
            result(FlutterError(code: "BLE_OFF", message: "Bluetooth apagado", details: nil))
            return
        }
        stopScan()
        discoveredPeripherals.removeAll()
        connectTargetUUID = nil
        scanResult = result

        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])
        scanTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.finishScan()
        }
    }

    func connect(address: String, result: @escaping FlutterResult) {
        guard centralManager.state == .poweredOn else {
            result(FlutterError(code: "BLE_OFF", message: "Bluetooth apagado", details: nil))
            return
        }

        // Disconnect existing
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
            connectedPeripheral = nil
            writeCharacteristic = nil
        }

        guard UUID(uuidString: address) != nil else {
            result(FlutterError(code: "BLE_INVALID", message: "UUID inválido", details: nil))
            return
        }

        log("connect: scanning for \(address)...")
        connectResult = result
        connectTargetUUID = address
        writeCharacteristic = nil
        pendingServiceCount = 0
        discoveredServiceCount = 0

        stopScan()

        // Scan with allowDuplicates:true so we re-discover even cached peripherals
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])

        // 15 second timeout
        connectTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            self.stopScan()
            self.log("connect: TIMEOUT after 15s")
            guard let res = self.connectResult else { return }
            self.connectResult = nil
            self.connectTargetUUID = nil
            if let p = self.connectedPeripheral {
                self.centralManager.cancelPeripheralConnection(p)
            }
            self.connectedPeripheral = nil
            res(FlutterError(code: "BLE_TIMEOUT",
                             message: "Tiempo de conexión agotado (15s). ¿La impresora está encendida?",
                             details: nil))
        }
    }

    func send(data: String, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripheral,
              let characteristic = writeCharacteristic else {
            result(FlutterError(code: "BLE_NOT_CONNECTED", message: "Sin conexión BLE", details: nil))
            return
        }

        guard let encoded = data.data(using: .utf8) else {
            result(FlutterError(code: "BLE_ENCODE", message: "Error codificando", details: nil))
            return
        }

        let mtu = peripheral.maximumWriteValueLength(for: writeType)
        let chunkSize = max(mtu, 20)
        let typeName = writeType == .withResponse ? "W" : "WnR"

        log("send: \(encoded.count)B, MTU=\(mtu), chunk=\(chunkSize), type=\(typeName), service=\(characteristic.service?.uuid.uuidString ?? "?"), char=\(characteristic.uuid.uuidString)")

        if writeType == .withResponse {
            sendResult = result
            pendingWriteCount = 0
            totalChunks = 0
            var offset = 0
            while offset < encoded.count {
                let end = min(offset + chunkSize, encoded.count)
                peripheral.writeValue(encoded.subdata(in: offset..<end), for: characteristic, type: .withResponse)
                pendingWriteCount += 1
                totalChunks += 1
                offset = end
            }
            log("send: queued \(totalChunks) chunks, waiting ACKs...")
        } else {
            var offset = 0
            var n = 0
            while offset < encoded.count {
                let end = min(offset + chunkSize, encoded.count)
                peripheral.writeValue(encoded.subdata(in: offset..<end), for: characteristic, type: .withoutResponse)
                n += 1
                offset = end
            }
            log("send: wrote \(n) chunks (\(encoded.count)B) withoutResponse")
            result(true)
        }
    }

    func disconnect(result: @escaping FlutterResult) {
        if let p = connectedPeripheral {
            disconnectResult = result
            centralManager.cancelPeripheralConnection(p)
        } else {
            result(true)
        }
        writeCharacteristic = nil
    }

    // MARK: - Helpers

    private func isStandardService(_ uuid: CBUUID) -> Bool {
        let s = uuid.uuidString.uppercased()
        for p in BlePrinterManager.skipServices {
            if s == p || s == "0000\(p)-0000-1000-8000-00805F9B34FB" { return true }
        }
        return false
    }

    private func stopScan() {
        scanTimer?.invalidate()
        scanTimer = nil
        if centralManager.isScanning { centralManager.stopScan() }
    }

    private func finishScan() {
        stopScan()
        let devices = discoveredPeripherals.map { ["name": $0.name, "address": $0.identifier] }
        log("scan: finished, \(devices.count) devices")
        let res = scanResult
        scanResult = nil
        res?(devices)
    }

    // MARK: - CBCentralManagerDelegate

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        log("state: \(central.state.rawValue)")
        if central.state != .poweredOn, scanResult != nil { finishScan() }
    }

    func centralManager(_ central: CBCentralManager,
                         didDiscover peripheral: CBPeripheral,
                         advertisementData: [String: Any],
                         rssi RSSI: NSNumber) {
        let name = peripheral.name ?? (advertisementData[CBAdvertisementDataLocalNameKey] as? String)
        let id = peripheral.identifier.uuidString

        // Add to discovered list for scan results
        if let n = name, !n.isEmpty, RSSI.intValue > -90 {
            if !discoveredPeripherals.contains(where: { $0.identifier == id }) {
                discoveredPeripherals.append((peripheral: peripheral, name: n, identifier: id))
            }
        }

        // Scan-to-connect: if this is our target, connect now
        if let target = connectTargetUUID, id == target {
            log("connect: found target! RSSI=\(RSSI), connecting...")
            stopScan()
            connectTargetUUID = nil
            connectedPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        log("connect: CONNECTED to \(peripheral.name ?? "?")")
        peripheral.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        log("connect: FAILED - \(error?.localizedDescription ?? "?")")
        connectTimer?.invalidate()
        connectTimer = nil
        connectTargetUUID = nil
        let res = connectResult
        connectResult = nil
        connectedPeripheral = nil
        res?(FlutterError(code: "BLE_CONNECT_FAIL", message: "Conexión fallida: \(error?.localizedDescription ?? "?")", details: nil))
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        log("disconnect: \(peripheral.name ?? "?")")
        connectedPeripheral = nil
        writeCharacteristic = nil
        if let res = disconnectResult { disconnectResult = nil; res(true) }
    }

    // MARK: - CBPeripheralDelegate

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let e = error {
            log("services: ERROR \(e.localizedDescription)")
            connectTimer?.invalidate(); connectTimer = nil
            let res = connectResult; connectResult = nil
            res?(FlutterError(code: "BLE_SVC_ERR", message: "Error servicios: \(e.localizedDescription)", details: nil))
            return
        }
        guard let services = peripheral.services, !services.isEmpty else {
            log("services: NONE found")
            connectTimer?.invalidate(); connectTimer = nil
            let res = connectResult; connectResult = nil
            res?(FlutterError(code: "BLE_NO_SVC", message: "Sin servicios BLE", details: nil))
            return
        }

        // Log and filter
        var vendorSvcs: [CBService] = []
        for svc in services {
            let std = isStandardService(svc.uuid)
            log("services: \(svc.uuid.uuidString) \(std ? "[std]" : "[vendor]")")
            if !std { vendorSvcs.append(svc) }
        }

        let toExplore: [CBService]
        if vendorSvcs.isEmpty {
            log("services: no vendor services, using all except GAP")
            toExplore = services.filter { $0.uuid.uuidString.uppercased() != "1800" }
            if toExplore.isEmpty {
                log("services: only GAP available, using it as last resort")
                pendingServiceCount = services.count
                discoveredServiceCount = 0
                for svc in services { peripheral.discoverCharacteristics(nil, for: svc) }
                return
            }
        } else {
            toExplore = vendorSvcs
        }

        pendingServiceCount = toExplore.count
        discoveredServiceCount = 0
        for svc in toExplore { peripheral.discoverCharacteristics(nil, for: svc) }
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didDiscoverCharacteristicsFor service: CBService,
                     error: Error?) {
        discoveredServiceCount += 1

        if let e = error {
            log("chars: ERROR for \(service.uuid): \(e.localizedDescription)")
            checkDone()
            return
        }

        guard let chars = service.characteristics else { checkDone(); return }

        for c in chars {
            let p = c.properties
            var flags: [String] = []
            if p.contains(.read) { flags.append("R") }
            if p.contains(.write) { flags.append("W") }
            if p.contains(.writeWithoutResponse) { flags.append("WnR") }
            if p.contains(.notify) { flags.append("N") }
            if p.contains(.indicate) { flags.append("I") }
            log("chars: \(service.uuid)/\(c.uuid) [\(flags.joined(separator: ","))]")
        }

        if writeCharacteristic == nil {
            // Prefer writeWithoutResponse (faster for bulk data), then write
            let wnr = chars.first { $0.properties.contains(.writeWithoutResponse) }
            let w = chars.first { $0.properties.contains(.write) }

            if let c = wnr {
                writeCharacteristic = c
                writeType = .withoutResponse
                log("chars: >>> SELECTED \(c.uuid)(WnR) @ \(service.uuid)")
            } else if let c = w {
                writeCharacteristic = c
                writeType = .withResponse
                log("chars: >>> SELECTED \(c.uuid)(W) @ \(service.uuid)")
            }
        }

        checkDone()
    }

    private func checkDone() {
        guard discoveredServiceCount >= pendingServiceCount else { return }
        if writeCharacteristic != nil {
            connectTimer?.invalidate(); connectTimer = nil
            log("connect: READY char=\(writeCharacteristic!.uuid) svc=\(writeCharacteristic!.service?.uuid.uuidString ?? "?") type=\(writeType == .withResponse ? "W" : "WnR")")
            let res = connectResult; connectResult = nil
            res?(true)
        } else {
            connectTimer?.invalidate(); connectTimer = nil
            log("connect: NO writable characteristic found")
            let res = connectResult; connectResult = nil
            res?(FlutterError(code: "BLE_NO_CHAR", message: "Sin característica de escritura", details: nil))
        }
    }

    func peripheral(_ peripheral: CBPeripheral,
                     didWriteValueFor characteristic: CBCharacteristic,
                     error: Error?) {
        if let e = error {
            log("write: ERROR \(e.localizedDescription)")
            if let res = sendResult { sendResult = nil; pendingWriteCount = 0; res(FlutterError(code: "BLE_WRITE", message: "Error: \(e.localizedDescription)", details: nil)) }
            return
        }
        pendingWriteCount -= 1
        if pendingWriteCount <= 0 {
            log("write: all \(totalChunks) chunks ACKed")
            if let res = sendResult { sendResult = nil; res(true) }
        }
    }
}
