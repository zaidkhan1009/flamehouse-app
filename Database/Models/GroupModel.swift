import SwiftData
import Foundation

@Model
final class GroupModel {
    @Attribute(.unique) var id: String
    var name: String
    var groupDescription: String
    var avatarURL: String?
    var currencyCode: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var creatorID: String

    var members: [UserModel]

    @Relationship(deleteRule: .cascade, inverse: \ExpenseModel.group)
    var expenses: [ExpenseModel]

    @Relationship(deleteRule: .cascade, inverse: \ActivityModel.group)
    var activities: [ActivityModel]

    @Relationship(deleteRule: .cascade, inverse: \SettlementModel.group)
    var settlements: [SettlementModel]

    init(
        id: String = UUID().uuidString,
        name: String,
        groupDescription: String = "",
        avatarURL: String? = nil,
        currencyCode: String = "USD",
        creatorID: String
    ) {
        self.id = id
        self.name = name
        self.groupDescription = groupDescription
        self.avatarURL = avatarURL
        self.currencyCode = currencyCode
        self.createdAt = .now
        self.updatedAt = .now
        self.isArchived = false
        self.creatorID = creatorID
        self.members = []
        self.expenses = []
        self.activities = []
        self.settlements = []
    }
}
