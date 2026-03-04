import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppExportEngine: ObservableObject {

    enum ExportFormat: String, CaseIterable {
        case csv
        case json
    }

    struct ExportResult {
        let url: URL
        let fileName: String
        let size: Int
    }

    @Published private(set) var lastError: String? = nil
    @Published private(set) var lastExport: ExportResult? = nil
    @Published private(set) var isExporting: Bool = false

    private let queue = DispatchQueue(label: "intuapp.export.queue")

    init() {}

    // MARK: - Public API

    func exportLedger(
        _ ledger: IntuAppLedgerStore,
        format: ExportFormat
    ) {

        guard isExporting == false else { return }

        isExporting = true
        lastError = nil
        lastExport = nil

        let entries = ledger.entries

        queue.async { [weak self] in
            guard let self else { return }

            let result: Result<ExportResult, Error>

            switch format {
            case .csv:
                result = self.exportCSV(entries)
            case .json:
                result = self.exportJSON(entries)
            }

            DispatchQueue.main.async {
                self.isExporting = false

                switch result {
                case .success(let r):
                    self.lastExport = r
                case .failure(let e):
                    self.lastError = e.localizedDescription
                }
            }
        }
    }

    // MARK: - CSV

    private func exportCSV(_ entries: [IntuAppLedgerStore.Entry]) -> Result<ExportResult, Error> {

        var lines: [String] = []

        lines.append("date,category,note,amount")

        let df = ISO8601DateFormatter()

        for e in entries {

            let date = df.string(from: e.date)
            let category = escape(e.category)
           // let note = escape(e.note)
            let amount = String(format: "%.2f", e.amount)

          //  let line = "\(date),\(category),\(note),\(amount)"
           // lines.append(line)
        }

        let csv = lines.joined(separator: "\n")

        return writeFile(
            data: Data(csv.utf8),
            name: makeFileName(ext: "csv")
        )
    }

    // MARK: - JSON

    private func exportJSON(_ entries: [IntuAppLedgerStore.Entry]) -> Result<ExportResult, Error> {

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        do {
            let data = try encoder.encode(entries)
            return writeFile(
                data: data,
                name: makeFileName(ext: "json")
            )
        } catch {
            return .failure(error)
        }
    }

    // MARK: - File writing

    private func writeFile(data: Data, name: String) -> Result<ExportResult, Error> {

        let dir = FileManager.default.temporaryDirectory
        let url = dir.appendingPathComponent(name)

        do {
            try data.write(to: url, options: .atomic)

            return .success(
                ExportResult(
                    url: url,
                    fileName: name,
                    size: data.count
                )
            )
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Helpers

    private func makeFileName(ext: String) -> String {

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm"

        let stamp = df.string(from: Date())

        return "intuapp_export_\(stamp).\(ext)"
    }

    private func escape(_ value: String) -> String {

        if value.contains(",") || value.contains("\"") || value.contains("\n") {

            let v = value.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(v)\""
        }

        return value
    }
}
