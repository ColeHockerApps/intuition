import SwiftUI
import Combine
import Foundation

struct IntuAppCategoryModel: Identifiable, Codable, Hashable {

    let id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var type: CategoryType

    enum CategoryType: String, Codable, CaseIterable {
        case expense
        case income
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        type: CategoryType
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
    }

    // MARK: - Helpers

    var color: Color {
        Color(hex: colorHex)
    }

    static func defaultCategories() -> [IntuAppCategoryModel] {
        [
            .init(name: "Food", icon: "fork.knife", colorHex: "#FF7A59", type: .expense),
            .init(name: "Transport", icon: "car.fill", colorHex: "#4A90E2", type: .expense),
            .init(name: "Shopping", icon: "bag.fill", colorHex: "#9B59B6", type: .expense),
            .init(name: "Health", icon: "heart.fill", colorHex: "#E74C3C", type: .expense),
            .init(name: "Bills", icon: "doc.text.fill", colorHex: "#F39C12", type: .expense),
            .init(name: "Salary", icon: "banknote.fill", colorHex: "#2ECC71", type: .income),
            .init(name: "Bonus", icon: "sparkles", colorHex: "#1ABC9C", type: .income)
        ]
    }
}

// MARK: - Color helper

extension Color {

    init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let r = Double((value >> 16) & 0xFF) / 255
        let g = Double((value >> 8) & 0xFF) / 255
        let b = Double(value & 0xFF) / 255

        self.init(red: r, green: g, blue: b)
    }
}
