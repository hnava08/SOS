import Foundation
import Combine

@MainActor
final class EmergencyHistoryStore: ObservableObject {
    static let shared = EmergencyHistoryStore()

    @Published private(set) var records: [EmergencyHistoryRecord] = []

    private let storageKey = "sos.emergencyHistory.v1"
    private let defaults: UserDefaults
    private(set) var activeRecordID: UUID?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    var sortedRecords: [EmergencyHistoryRecord] {
        records.sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    func startRecord(
        type: EmergencyType,
        unitNumber: String,
        etaMinutes: Int,
        addressLabel: String,
        latitude: Double,
        longitude: Double
    ) -> EmergencyHistoryRecord {
        let now = Date()
        let record = EmergencyHistoryRecord(
            id: UUID(),
            createdAt: now,
            updatedAt: now,
            emergencyTypeRaw: type.rawValue,
            emergencyTitle: type.title,
            unitNumber: unitNumber,
            etaMinutes: etaMinutes,
            addressLabel: addressLabel,
            latitude: latitude,
            longitude: longitude,
            outcome: .dispatched
        )
        records.insert(record, at: 0)
        activeRecordID = record.id
        persist()
        return record
    }

    func markArrived(unitNumber: String? = nil) {
        guard let id = activeRecordID,
              let index = records.firstIndex(where: { $0.id == id }) else {
            // Fallback: update most recent matching unit
            if let unitNumber,
               let index = records.firstIndex(where: { $0.unitNumber == unitNumber && $0.outcome == .dispatched }) {
                records[index].outcome = .arrived
                records[index].updatedAt = Date()
                persist()
            }
            return
        }
        records[index].outcome = .arrived
        records[index].updatedAt = Date()
        activeRecordID = nil
        persist()
    }

    func markCancelled() {
        guard let id = activeRecordID,
              let index = records.firstIndex(where: { $0.id == id }) else { return }
        if records[index].outcome == .dispatched {
            records[index].outcome = .cancelled
            records[index].updatedAt = Date()
        }
        activeRecordID = nil
        persist()
    }

    func delete(_ id: UUID) {
        records.removeAll { $0.id == id }
        if activeRecordID == id { activeRecordID = nil }
        persist()
    }

    func clearAll() {
        records.removeAll()
        activeRecordID = nil
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([EmergencyHistoryRecord].self, from: data) else {
            records = []
            return
        }
        records = saved
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
