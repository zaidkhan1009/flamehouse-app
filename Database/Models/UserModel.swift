import SwiftData
import Foundation

@Model
final class UserModel {
    @Attribute(.unique) var id: String
    var name: String
    var email: String
    var avatarURL: String?
    var phoneNumber: String?
    var preferredCurrencyCode: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \GroupModel.members)
    var groups: [GroupModel]

    @Relationship(deleteRule: .cascade)
    var paidExpenses: [ExpenseModel]

    @Relationship(deleteRule: .cascade)
    var initiatedSettlements: [SettlementModel]

    init(
        id: String = UUID().uuidString,
        name: String,
        email: String,
        avatarURL: String? = nil,
        phoneNumber: String? = nil,
        preferredCurrencyCode: String = "USD"
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.phoneNumber = phoneNumber
        self.preferredCurrencyCode = preferredCurrencyCode
        self.createdAt = .now
        self.updatedAt = .now
        self.groups = []
        self.paidExpenses = []
        self.initiatedSettlements = []
    }
}
