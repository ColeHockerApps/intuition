import SwiftUI
import Combine
import Foundation

@MainActor
final class IntuAppCurrencyFormatter: ObservableObject {

    static let shared = IntuAppCurrencyFormatter()

    @Published var currencyCode: String
    @Published var localeIdentifier: String

    private let currencyKey = "intuapp.currency.code"
    private let localeKey = "intuapp.locale.id"

    private init() {
        let defaults = UserDefaults.standard

        if let storedCurrency = defaults.string(forKey: currencyKey) {
            currencyCode = storedCurrency
        } else {
            currencyCode = Locale.current.currency?.identifier ?? "USD"
        }

        if let storedLocale = defaults.string(forKey: localeKey) {
            localeIdentifier = storedLocale
        } else {
            localeIdentifier = Locale.current.identifier
        }
    }

    // MARK: - Configuration

    func setCurrency(_ code: String) {
        currencyCode = code
        UserDefaults.standard.set(code, forKey: currencyKey)
    }

    func setLocale(_ identifier: String) {
        localeIdentifier = identifier
        UserDefaults.standard.set(identifier, forKey: localeKey)
    }

    // MARK: - Formatting

    func string(from value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.maximumFractionDigits = 2

        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func string(fromDecimal value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.maximumFractionDigits = 2

        return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
    }

    func compactString(from value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Parsing

    func value(from string: String) -> Double? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: localeIdentifier)

        return formatter.number(from: string)?.doubleValue
    }

    func decimal(from string: String) -> Decimal? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale(identifier: localeIdentifier)

        return formatter.number(from: string)?.decimalValue
    }
}
