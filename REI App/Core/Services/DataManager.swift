import Foundation
import Combine
import SwiftUI

// MARK: - DataManager Protocol (following Dependency Inversion principle)
protocol DataManaging {
    // Reminders
    func saveReminders(_ reminders: [Reminder])
    func loadReminders() -> [Reminder]
    func addReminder(_ reminder: Reminder)
    func updateReminder(_ reminder: Reminder)
    func deleteReminder(withId id: UUID)
    
    // Expenses
    func saveExpenses(_ expenses: [Expense])
    func loadExpenses() -> [Expense]
    func addExpense(_ expense: Expense)
    func updateExpense(_ expense: Expense)
    func deleteExpense(withId id: UUID)
    
    // Total Amount
    func saveTotalAmount(_ totalAmount: TotalAmount)
    func loadTotalAmount() -> TotalAmount?
    func updateTotalAmount(_ amount: Double, description: String)
    func getTotalAmountAfterExpenses() -> Double
    func getRemainingPercentage() -> Double
    func getSpentAmount() -> Double
    func getSpentPercentage() -> Double
    func getExpensesByCategory() -> [ExpenseCategory: Double]
    func getTopExpenseCategories(limit: Int) -> [(category: ExpenseCategory, amount: Double)]
    func hasTotalAmountSet() -> Bool
    func canCoverExpense(_ amount: Double) -> Bool
    func getRecentExpenses(limit: Int) -> [Expense]
    
    // Budgets
    func saveBudgets(_ budgets: [Budget])
    func loadBudgets() -> [Budget]
    func addBudget(_ budget: Budget)
    func updateBudget(_ budget: Budget)
    func deleteBudget(withId id: UUID)
    func getRelevantExpensesForBudget(_ budget: Budget) -> [Expense]
    func getBudgetAnalysis(for budget: Budget) -> BudgetAnalysis
    
    // Interest Calculations
    func saveInterestCalculations(_ calculations: [InterestCalculation])
    func loadInterestCalculations() -> [InterestCalculation]
    func addInterestCalculation(_ calculation: InterestCalculation)
    func updateInterestCalculation(_ calculation: InterestCalculation)
    func deleteInterestCalculation(withId id: UUID)
}

// MARK: - Data Manager Implementation
class DataManager: DataManaging, ObservableObject {
    // Published properties
    @Published var reminders: [Reminder] = []
    @Published var expenses: [Expense] = []
    @Published var budgets: [Budget] = []
    @Published var interestCalculations: [InterestCalculation] = []
    @Published var totalAmount: TotalAmount?
    
    // UserDefaults keys
    private enum Keys {
        static let reminders = "reminders"
        static let expenses = "expenses"
        static let budgets = "budgets"
        static let interestCalculations = "interestCalculations"
        static let totalAmount = "totalAmount"
    }
    
    // MARK: - Initialization
    init() {
        loadAllData()
    }
    
    private func loadAllData() {
        reminders = loadReminders()
        expenses = loadExpenses()
        budgets = loadBudgets()
        interestCalculations = loadInterestCalculations()
        totalAmount = loadTotalAmount()
    }
    
    // MARK: - Reminders
    func saveReminders(_ reminders: [Reminder]) {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: Keys.reminders)
            self.reminders = reminders
        }
    }
    
    func loadReminders() -> [Reminder] {
        if let data = UserDefaults.standard.data(forKey: Keys.reminders),
           let decoded = try? JSONDecoder().decode([Reminder].self, from: data) {
            return decoded
        }
        return []
    }
    
    func addReminder(_ reminder: Reminder) {
        reminders.append(reminder)
        saveReminders(reminders)
    }
    
    func updateReminder(_ reminder: Reminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            let oldReminder = reminders[index]
            reminders[index] = reminder
            saveReminders(reminders)
            
            // If reminder was marked as completed, cancel its notification
            if !oldReminder.isCompleted && reminder.isCompleted {
                NotificationManager.shared.cancelNotification(for: reminder.id)
            }
            // If due date changed or reminder was unmarked as completed, reschedule notification
            else if oldReminder.dueDate != reminder.dueDate || (oldReminder.isCompleted && !reminder.isCompleted) {
                NotificationManager.shared.scheduleReminderNotification(for: reminder)
            }
        }
    }
    
    func deleteReminder(withId id: UUID) {
        reminders.removeAll { $0.id == id }
        saveReminders(reminders)
        
        // Cancel notification for the deleted reminder
        NotificationManager.shared.cancelNotification(for: id)
    }
    
    // MARK: - Expenses
    func saveExpenses(_ expenses: [Expense]) {
        if let encoded = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(encoded, forKey: Keys.expenses)
            self.expenses = expenses
        }
    }
    
    func loadExpenses() -> [Expense] {
        if let data = UserDefaults.standard.data(forKey: Keys.expenses),
           let decoded = try? JSONDecoder().decode([Expense].self, from: data) {
            return decoded
        }
        return []
    }
    
    func addExpense(_ expense: Expense) {
        expenses.append(expense)
        saveExpenses(expenses)
    }
    
    func updateExpense(_ expense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == expense.id }) {
            expenses[index] = expense
            saveExpenses(expenses)
        }
    }
    
    func deleteExpense(withId id: UUID) {
        expenses.removeAll { $0.id == id }
        saveExpenses(expenses)
    }
    
    // MARK: - Total Amount Methods
    func saveTotalAmount(_ totalAmount: TotalAmount) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(totalAmount)
            UserDefaults.standard.set(data, forKey: Keys.totalAmount)
            self.totalAmount = totalAmount
        } catch {
            print("Error saving total amount: \(error)")
        }
    }
    
    func loadTotalAmount() -> TotalAmount? {
        guard let data = UserDefaults.standard.data(forKey: Keys.totalAmount) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(TotalAmount.self, from: data)
        } catch {
            print("Error loading total amount: \(error)")
            return nil
        }
    }
    
    func updateTotalAmount(_ amount: Double, description: String = "Total Balance") {
        let newTotal = TotalAmount(amount: amount, description: description)
        saveTotalAmount(newTotal)
    }
    
    func getTotalAmountAfterExpenses() -> Double {
        guard let totalAmount = totalAmount else {
            return 0
        }
        
        let totalExpenses = expenses.reduce(0) { $0 + $1.amount }
        return max(0, totalAmount.amount - totalExpenses)
    }
    
    func getRemainingPercentage() -> Double {
        guard let totalAmount = totalAmount, totalAmount.amount > 0 else {
            return 0
        }
        
        let remaining = getTotalAmountAfterExpenses()
        return (remaining / totalAmount.amount) * 100
    }
    
    func getSpentAmount() -> Double {
      guard totalAmount != nil else {
            return 0
        }
        
        return expenses.reduce(0) { $0 + $1.amount }
    }
    
    func getSpentPercentage() -> Double {
        guard let totalAmount = totalAmount, totalAmount.amount > 0 else {
            return 0
        }
        
        let spent = getSpentAmount()
        return (spent / totalAmount.amount) * 100
    }
    
    func getExpensesByCategory() -> [ExpenseCategory: Double] {
        var categoryTotals: [ExpenseCategory: Double] = [:]
        
        for category in ExpenseCategory.allCases {
            categoryTotals[category] = 0
        }
        
        for expense in expenses {
            categoryTotals[expense.category, default: 0] += expense.amount
        }
        
        return categoryTotals
    }
    
    func getTopExpenseCategories(limit: Int = 3) -> [(category: ExpenseCategory, amount: Double)] {
        let categoryTotals = getExpensesByCategory()
        
        let sortedCategories = categoryTotals.sorted { $0.value > $1.value }
            .prefix(limit)
            .map { (category: $0.key, amount: $0.value) }
        
        return Array(sortedCategories)
    }
    
    func hasTotalAmountSet() -> Bool {
        return totalAmount != nil
    }
    
    func canCoverExpense(_ amount: Double) -> Bool {
      guard totalAmount != nil else {
            return false
        }
        
        return getTotalAmountAfterExpenses() >= amount
    }
    
    func getRecentExpenses(limit: Int = 5) -> [Expense] {
        return expenses.sorted { $0.date > $1.date }.prefix(limit).map { $0 }
    }
    
    // MARK: - Budgets
    func saveBudgets(_ budgets: [Budget]) {
        if let encoded = try? JSONEncoder().encode(budgets) {
            UserDefaults.standard.set(encoded, forKey: Keys.budgets)
            self.budgets = budgets
        }
    }
    
    func loadBudgets() -> [Budget] {
        if let data = UserDefaults.standard.data(forKey: Keys.budgets),
           let decoded = try? JSONDecoder().decode([Budget].self, from: data) {
            return decoded
        }
        return []
    }
    
    func addBudget(_ budget: Budget) {
        budgets.append(budget)
        saveBudgets(budgets)
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
            saveBudgets(budgets)
        }
    }
    
    func deleteBudget(withId id: UUID) {
        budgets.removeAll { $0.id == id }
        saveBudgets(budgets)
    }
    
    func getRelevantExpensesForBudget(_ budget: Budget) -> [Expense] {
        return expenses.filter { expense in
            let isInDateRange = expense.date >= budget.startDate && expense.date <= budget.endDate
            
            if let budgetCategory = budget.category {
                return isInDateRange && expense.category == budgetCategory
            } else {
                return isInDateRange
            }
        }
    }
    
    func getBudgetAnalysis(for budget: Budget) -> BudgetAnalysis {
        let relevantExpenses = getRelevantExpensesForBudget(budget)
        let totalSpent = relevantExpenses.reduce(0) { $0 + $1.amount }
        let remainingAmount = budget.remainingAmount(expenses: relevantExpenses)
        let percentageUsed = budget.percentageUsed(expenses: relevantExpenses)
        
        return BudgetAnalysis(
            budget: budget,
            totalBudget: budget.amount,
            totalSpent: totalSpent,
            remainingAmount: remainingAmount,
            percentageUsed: percentageUsed,
            expenses: relevantExpenses
        )
    }
    
    // MARK: - Interest Calculations
    func saveInterestCalculations(_ calculations: [InterestCalculation]) {
        if let encoded = try? JSONEncoder().encode(calculations) {
            UserDefaults.standard.set(encoded, forKey: Keys.interestCalculations)
            self.interestCalculations = calculations
        }
    }
    
    func loadInterestCalculations() -> [InterestCalculation] {
        if let data = UserDefaults.standard.data(forKey: Keys.interestCalculations),
           let decoded = try? JSONDecoder().decode([InterestCalculation].self, from: data) {
            return decoded
        }
        return []
    }
    
    func addInterestCalculation(_ calculation: InterestCalculation) {
        interestCalculations.append(calculation)
        saveInterestCalculations(interestCalculations)
    }
    
    func updateInterestCalculation(_ calculation: InterestCalculation) {
        if let index = interestCalculations.firstIndex(where: { $0.id == calculation.id }) {
            interestCalculations[index] = calculation
            saveInterestCalculations(interestCalculations)
        }
    }
    
    func deleteInterestCalculation(withId id: UUID) {
        interestCalculations.removeAll { $0.id == id }
        saveInterestCalculations(interestCalculations)
    }
} 
