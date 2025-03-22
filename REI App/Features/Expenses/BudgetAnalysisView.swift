import SwiftUI
import Charts

struct BudgetAnalysisView: View {
    @EnvironmentObject private var dataManager: DataManager
    let budget: Budget
    
    private var analysis: BudgetAnalysis {
        return dataManager.getBudgetAnalysis(for: budget)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Budget overview card
                overviewCard
                
                // Spending breakdown
                if !analysis.expenses.isEmpty {
                    spendingBreakdownCard
                    recentTransactionsCard
                }
            }
            .padding(.vertical)
            .navigationTitle("Budget Analysis")
        }
    }
    
    // MARK: - Overview Card
    private var overviewCard: some View {
        CardView {
            VStack(spacing: 16) {
                headerSection
                progressBarSection
                Divider()
                dailyAllowanceSection
            }
        }
        .padding(.horizontal)
    }
    
    private var headerSection: some View {
        HStack {
            budgetInfoSection
            Spacer()
            budgetStatusSection
        }
    }
    
    private var budgetInfoSection: some View {
        VStack(alignment: .leading) {
            Text(budget.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if let category = budget.category {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.rawValue)
                        .foregroundColor(.secondary)
                }
            }
            
            Text("\(formattedDate(budget.startDate)) - \(formattedDate(budget.endDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var budgetStatusSection: some View {
        VStack(alignment: .trailing) {
            HStack {
                Image(systemName: analysis.status.icon)
                    .foregroundColor(analysis.status.color)
                Text(analysis.status.description)
                    .font(.headline)
                    .foregroundColor(analysis.status.color)
            }
            
            Text("Total Budget: \(budget.formattedAmount)")
                .font(.subheadline)
        }
    }
    
    private var progressBarSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Used: \(formatCurrency(analysis.totalSpent))")
                Spacer()
                Text("Remaining: \(formatCurrency(analysis.remainingAmount))")
            }
            .font(.subheadline)
            
            progressBar
            
            Text("\(Int(analysis.percentageUsed))% used")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var progressBar: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .frame(height: 12)
                .foregroundColor(Color.gray.opacity(0.2))
                .cornerRadius(6)
            
            progressFill
        }
    }
    
    private var progressFill: some View {
        let width = max(0, min(1, analysis.percentageUsed / 100)) * (UIScreen.main.bounds.width - 40)
        let color: Color = progressColor
        
        return Rectangle()
            .frame(width: width, height: 12)
            .foregroundColor(color)
            .cornerRadius(6)
    }
    
    private var progressColor: Color {
        if analysis.percentageUsed >= 100 {
            return Color.red
        } else if analysis.percentageUsed >= 80 {
            return Color.orange
        } else {
            return Color.green
        }
    }
    
    private var dailyAllowanceSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Daily Allowance")
                    .font(.headline)
                Text("Spending limit to stay within budget")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(analysis.formattedDailyAllowance)
                .font(.title2)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Spending Breakdown Card
    private var spendingBreakdownCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Spending Breakdown")
                    .font(.headline)
                
                spendingChart
                categoryBreakdownList
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var spendingChart: some View {
        if #available(iOS 16.0, *) {
            chartView
        } else {
            legacyChartView
        }
    }
    
    @available(iOS 16.0, *)
    private var chartView: some View {
        Chart {
            ForEach(analysis.spendingByCategory, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.6),
                    angularInset: 1
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(5)
                .annotation(position: .overlay) {
                    Text("\(Int(item.percentage))%")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(height: 200)
    }
    
    private var legacyChartView: some View {
        HStack {
            ForEach(analysis.topSpendingCategories, id: \.category) { item in
                categoryCircle(for: item)
                if let last = analysis.topSpendingCategories.last, item.category != last.category {
                    Spacer()
                }
            }
        }
    }
    
    private func categoryCircle(for item: (category: ExpenseCategory, amount: Double, percentage: Double)) -> some View {
        VStack {
            Circle()
                .fill(item.category.color)
                .frame(width: 20, height: 20)
            Text(item.category.rawValue)
                .font(.caption)
            Text("\(Int(item.percentage))%")
                .font(.caption)
                .fontWeight(.bold)
        }
    }
    
    private var categoryBreakdownList: some View {
        VStack(spacing: 12) {
            ForEach(analysis.spendingByCategory, id: \.category) { item in
                categoryRow(for: item)
            }
        }
    }
    
    private func categoryRow(for item: (category: ExpenseCategory, amount: Double, percentage: Double)) -> some View {
        HStack {
            Circle()
                .fill(item.category.color)
                .frame(width: 12, height: 12)
            
            Text(item.category.rawValue)
                .font(.subheadline)
            
            Spacer()
            
            Text(formatCurrency(item.amount))
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text("(\(Int(item.percentage))%)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Recent Transactions Card
    private var recentTransactionsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Recent Transactions")
                    .font(.headline)
                
                transactionsList
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var transactionsList: some View {
        if analysis.expenses.isEmpty {
            emptyTransactionsMessage
        } else {
            recentTransactionsContent
        }
    }
    
    private var emptyTransactionsMessage: some View {
        HStack {
            Spacer()
            Text("No transactions in this budget period")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical)
    }
    
    private var recentTransactionsContent: some View {
        VStack {
            let sortedExpenses = Array(analysis.expenses.prefix(5).sorted(by: { $0.date > $1.date }))
            
            ForEach(sortedExpenses, id: \.id) { expense in
                transactionRow(for: expense)
                
                if expense != sortedExpenses.last {
                    Divider()
                }
            }
            
            if analysis.expenses.count > 5 {
                seeAllTransactionsButton
            }
        }
    }
    
    private func transactionRow(for expense: Expense) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(expense.title)
                    .font(.subheadline)
                
                HStack {
                    Image(systemName: expense.category.icon)
                        .foregroundColor(expense.category.color)
                        .font(.caption)
                    
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedDate(expense.date, includeTime: false))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(expense.formattedAmount)
                .font(.headline)
                .foregroundColor(.primary)
        }
    }
    
    private var seeAllTransactionsButton: some View {
        HStack {
            Spacer()
            Text("See All (\(analysis.expenses.count) transactions)")
                .font(.footnote)
                .foregroundColor(AppColors.primary)
            Spacer()
        }
        .padding(.top)
    }
    
    // MARK: - Helper Methods
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
    
    private func formattedDate(_ date: Date, includeTime: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = includeTime ? .short : .none
        return formatter.string(from: date)
    }
}

struct BudgetAnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BudgetAnalysisView(
                budget: Budget(
                    name: "Monthly Budget",
                    amount: 2000.0,
                    category: nil,
                    startDate: Date().startOfMonth,
                    endDate: Date().endOfMonth
                )
            )
            .environmentObject(DataManager())
        }
    }
}

// Extensions for Date to get start and end of month
extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    var endOfMonth: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.month = 1
        components.day = -1
        return calendar.date(byAdding: components, to: self.startOfMonth)!
    }
} 