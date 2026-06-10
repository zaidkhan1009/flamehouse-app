import SwiftUI

enum AppRoute: Hashable {
    case dashboard
    case groupDetail(String)
    case expenseDetail(String)
    case addExpense(groupID: String)
    case settlement(groupID: String)
    case profile
}

enum AppSheet: Identifiable {
    case createGroup
    case addExpense(groupID: String)
    case settleUp(groupID: String)
    case currencyPicker

    var id: String {
        switch self {
        case .createGroup: return "createGroup"
        case .addExpense(let id): return "addExpense-\(id)"
        case .settleUp(let id): return "settleUp-\(id)"
        case .currencyPicker: return "currencyPicker"
        }
    }
}

@Observable
final class AppCoordinator {
    var path = NavigationPath()
    var activeSheet: AppSheet?
    var isAuthenticated = false

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    func popToRoot() {
        path.removeLast(path.count)
    }

    func present(_ sheet: AppSheet) {
        activeSheet = sheet
    }

    func dismiss() {
        activeSheet = nil
    }

    func signIn() {
        isAuthenticated = true
    }

    func signOut() {
        isAuthenticated = false
        popToRoot()
    }
}

struct AppCoordinatorView: View {
    @Environment(DIContainer.self) private var container
    @State private var coordinator = AppCoordinator()

    var body: some View {
        Group {
            if coordinator.isAuthenticated {
                authenticatedView
            } else {
                AuthFlowView()
                    .environment(coordinator)
            }
        }
        .environment(coordinator)
        .onAppear {
            coordinator.isAuthenticated = container.authService.isAuthenticated
        }
    }

    private var authenticatedView: some View {
        NavigationStack(path: $coordinator.path) {
            MainTabView()
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
        }
        .sheet(item: $coordinator.activeSheet) { sheet in
            sheetView(for: sheet)
        }
    }

    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            DashboardView()
        case .groupDetail(let id):
            GroupDetailView(groupID: id)
        case .expenseDetail(let id):
            ExpenseDetailView(expenseID: id)
        case .addExpense(let groupID):
            AddExpenseView(groupID: groupID)
        case .settlement(let groupID):
            SettlementView(groupID: groupID)
        case .profile:
            ProfileView()
        }
    }

    @ViewBuilder
    private func sheetView(for sheet: AppSheet) -> some View {
        switch sheet {
        case .createGroup:
            NavigationStack {
                CreateGroupView()
            }
        case .addExpense(let groupID):
            NavigationStack {
                AddExpenseView(groupID: groupID)
            }
        case .settleUp(let groupID):
            NavigationStack {
                SettlementView(groupID: groupID)
            }
        case .currencyPicker:
            NavigationStack {
                CurrencyPickerView()
            }
        }
    }
}
