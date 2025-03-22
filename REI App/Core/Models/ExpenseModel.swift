import Foundation
import SwiftUI

// MARK: - Global Constants
let CURRENCY_SYMBOL = "₹" // Rupee symbol

// MARK: - Currency and Formatting
func formatCurrency(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = CURRENCY_SYMBOL
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? "\(CURRENCY_SYMBOL)\(String(format: "%.2f", value))"
}

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case food = "Food"
    case transportation = "Transportation"
    case housing = "Housing"
    case utilities = "Utilities"
    case entertainment = "Entertainment"
    case shopping = "Shopping"
    case healthcare = "Healthcare"
    case education = "Education"
    case travel = "Travel"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .food: return .orange
        case .transportation: return .blue
        case .housing: return .purple
        case .utilities: return .gray
        case .entertainment: return .pink
        case .shopping: return .green
        case .healthcare: return .red
        case .education: return .cyan
        case .travel: return .yellow
        case .other: return .brown
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .housing: return "house.fill"
        case .utilities: return "bolt.fill"
        case .entertainment: return "tv.fill"
        case .shopping: return "bag.fill"
        case .healthcare: return "heart.text.square.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .other: return "questionmark.circle.fill"
        }
    }
}

struct Expense: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var amount: Double
    var date: Date
    var category: ExpenseCategory
    var notes: String = ""
    var isRecurring: Bool = false
    var recurringFrequency: RecurringFrequency? = nil
    var createdAt: Date = Date()
    
    var formattedAmount: String {
        return formatCurrency(amount)
    }
    
    static func == (lhs: Expense, rhs: Expense) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - TotalAmount Model
struct TotalAmount: Codable, Identifiable {
    var id: UUID
    var amount: Double
    var description: String
    var lastUpdated: Date
    
    init(amount: Double, description: String = "Total Balance") {
        self.id = UUID()
        self.amount = amount
        self.description = description
        self.lastUpdated = Date()
    }
}

enum RecurringFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var id: String { self.rawValue }
}

struct Budget: Identifiable, Equatable, Codable {
    let id: UUID
    let name: String
    let amount: Double
    let category: ExpenseCategory?
    let startDate: Date
    let endDate: Date
    let createdAt: Date
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = CURRENCY_SYMBOL
        return formatter.string(from: NSNumber(value: amount)) ?? "\(CURRENCY_SYMBOL)\(amount)"
    }
    
    init(id: UUID = UUID(), name: String, amount: Double, category: ExpenseCategory? = nil, startDate: Date, endDate: Date, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.amount = amount
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }
    
    static func == (lhs: Budget, rhs: Budget) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Calculate remaining amount based on expenses
    func remainingAmount(expenses: [Expense]) -> Double {
        let filteredExpenses = expenses.filter { expense in
            // Filter expenses by date and category
            let isInDateRange = expense.date >= startDate && expense.date <= endDate
            
            if let budgetCategory = category {
                return isInDateRange && expense.category == budgetCategory
            } else {
                return isInDateRange
            }
        }
        
        let totalSpent = filteredExpenses.reduce(0) { $0 + $1.amount }
        return max(0, amount - totalSpent)
    }
    
    // Calculate percentage used
    func percentageUsed(expenses: [Expense]) -> Double {
        let remaining = remainingAmount(expenses: expenses)
        return ((amount - remaining) / amount) * 100
    }
    
    // Check if budget is exceeded
    func isExceeded(expenses: [Expense]) -> Bool {
        return remainingAmount(expenses: expenses) <= 0
    }
    
    // Format the remaining amount
    func formattedRemainingAmount(expenses: [Expense]) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = CURRENCY_SYMBOL
        let remaining = remainingAmount(expenses: expenses)
        return formatter.string(from: NSNumber(value: remaining)) ?? "\(CURRENCY_SYMBOL)\(remaining)"
    }
}

// New struct for budget analysis
struct BudgetAnalysis {
    let budget: Budget
    let totalBudget: Double
    let totalSpent: Double
    let remainingAmount: Double
    let percentageUsed: Double
    let expenses: [Expense]
    
    // Spending breakdown by category
    var spendingByCategory: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
        let categoryTotals = Dictionary(grouping: expenses) { $0.category }
            .mapValues { categoryExpenses in
                categoryExpenses.reduce(0) { $0 + $1.amount }
            }
        
        return ExpenseCategory.allCases.compactMap { category in
            guard let amount = categoryTotals[category], amount > 0 else { return nil }
            let percentage = (amount / totalSpent) * 100
            return (category: category, amount: amount, percentage: percentage)
        }.sorted { $0.amount > $1.amount }
    }
    
    // Get top spending categories
    var topSpendingCategories: [(category: ExpenseCategory, amount: Double, percentage: Double)] {
        return spendingByCategory.prefix(3).map { $0 }
    }
    
    // Get status of the budget
    var status: BudgetStatus {
        let percentRemaining = (remainingAmount / totalBudget) * 100
        if remainingAmount <= 0 {
            return .exceeded
        } else if percentRemaining < 20 {
            return .warning
        } else {
            return .good
        }
    }
    
    // Calculate daily spending allowance for remaining budget period
    var dailyAllowance: Double {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // If budget period is over or exceeded
        guard currentDate <= budget.endDate && remainingAmount > 0 else {
            return 0
        }
        
        let daysRemaining = max(1, calendar.dateComponents([.day], from: currentDate, to: budget.endDate).day ?? 1)
        return remainingAmount / Double(daysRemaining)
    }
    
    // Format the daily allowance
    var formattedDailyAllowance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = CURRENCY_SYMBOL
        return formatter.string(from: NSNumber(value: dailyAllowance)) ?? "\(CURRENCY_SYMBOL)\(dailyAllowance)"
    }
}

enum BudgetStatus {
    case good
    case warning
    case exceeded
    
    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .exceeded: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .exceeded: return "xmark.circle.fill"
        }
    }
    
    var description: String {
        switch self {
        case .good: return "On Track"
        case .warning: return "Budget Running Low"
        case .exceeded: return "Budget Exceeded"
        }
    }
} 