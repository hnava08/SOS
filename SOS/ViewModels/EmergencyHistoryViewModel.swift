import Foundation
import Combine

@MainActor
final class EmergencyHistoryViewModel: ObservableObject {
    @Published var records: [EmergencyHistoryRecord] = []
    @Published var selectedRecord: EmergencyHistoryRecord?

    private let store: EmergencyHistoryStore
    private var cancellables = Set<AnyCancellable>()

    init(store: EmergencyHistoryStore = .shared) {
        self.store = store
        self.records = store.sortedRecords

        store.$records
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.records = store.sortedRecords
            }
            .store(in: &cancellables)
    }

    func delete(_ record: EmergencyHistoryRecord) {
        store.delete(record.id)
    }

    func clearAll() {
        store.clearAll()
    }
}
