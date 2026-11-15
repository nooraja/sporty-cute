import CoreBluetooth
import Foundation

@MainActor
final class TransitionScanner: NSObject {
    private var central: CBCentralManager?
    private var expectedService: CBUUID?

    var onDetection: (() -> Void)?
    var onStatus: ((String) -> Void)?

    func watch(service: UUID) {
        expectedService = CBUUID(nsuuid: service)
        if central == nil {
            central = CBCentralManager(delegate: self, queue: nil)
        } else if let central {
            updateScan(central)
        }
    }

    func stop() {
        expectedService = nil
        central?.stopScan()
    }

    private func updateScan(_ central: CBCentralManager) {
        guard let expectedService else { return }

        switch central.state {
        case .poweredOn:
            central.stopScan()
            central.scanForPeripherals(withServices: [expectedService])
            onStatus?("Listening for transition beacon")
        case .unsupported, .unauthorized, .poweredOff:
            onStatus?("Bluetooth unavailable. Manual transition is ready.")
        default:
            break
        }
    }
}

// A nil dispatch queue delivers central events on the main queue.
extension TransitionScanner: @MainActor CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        updateScan(central)
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let services = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID]
        let overflow = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID]
        let signal = RSSI.intValue
        guard let expectedService,
              (services?.contains(expectedService) == true || overflow?.contains(expectedService) == true),
              (-85 ... -1).contains(signal) else { return }

        stop()
        onDetection?()
    }
}
