import SwiftUI
import Charts
import UIKit

struct ExpensesView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var activeTab = 0
    @State private var showingAddExpenseSheet = false
    @State private var showingAddBudgetSheet = false
    @State private var showingAddTotalAmountSheet = false
    @State private var editingExpense: Expense? = nil
    @State private var editingBudget: Budget? = nil
    @State private var searchText = ""
    @State private var timeFilter: TimeFilter = .month
    
    enum TimeFilter: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var id: String { self.rawValue }
    }
    
    var filteredExpenses: [Expense] {
        let filtered = dataManager.expenses.filter { expense in
            if searchText.isEmpty {
                return true
            } else {
                return expense.title.localizedCaseInsensitiveContains(searchText) ||
                    expense.notes.localizedCaseInsensitiveContains(searchText) ||
                    expense.category.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.filter { expense in
            let calendar = Calendar.current
            let now = Date()
            
            switch timeFilter {
            case .week:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
                return expense.date >= weekAgo
            case .month:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!
                return expense.date >= monthAgo
            case .year:
                let yearAgo = calendar.date(byAdding: .year, value: -1, to: now)!
                return expense.date >= yearAgo
            }
        }.sorted(by: { $0.date > $1.date })
    }
    
    var totalExpenses: Double {
        filteredExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var groupedByCategory: [ExpenseCategory: Double] {
        Dictionary(grouping: filteredExpenses, by: { $0.category })
            .mapValues { expenses in
                expenses.reduce(0) { $0 + $1.amount }
            }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Segment control for tab selection
            SegmentedPicker(
                items: ["Expenses", "Budgets", "Insights"],
                selectedIndex: $activeTab
            )
            .padding()
            
            // Total amount display
          if dataManager.totalAmount != nil {
                totalAmountDisplay
            }
            
            // Tab content
            TabView(selection: $activeTab) {
                // Tab 1: Expenses List
                expensesListView
                    .tag(0)
                
                // Tab 2: Budgets
                budgetsView
                    .tag(1)
                
                // Tab 3: Insights
                insightsView
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .navigationTitle("Expenses")
        .sheet(isPresented: $showingAddExpenseSheet) {
            NavigationView {
                ExpenseFormView(
                    expense: Expense(
                        title: "",
                        amount: 0.0,
                        date: Date(),
                        category: .other
                    ),
                    isNew: true
                )
                .environmentObject(dataManager)
            }
        }
        .sheet(item: $editingExpense) { expense in
            NavigationView {
                ExpenseFormView(expense: expense, isNew: false)
                    .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingAddBudgetSheet) {
            NavigationView {
                BudgetFormView(
                    budget: Budget(
                        name: "",
                        amount: 0.0,
                        startDate: Date(),
                        endDate: Calendar.current.date(byAdding: .month, value: 1, to: Date())!
                    ),
                    isNew: true
                )
                .environmentObject(dataManager)
            }
        }
        .sheet(item: $editingBudget) { budget in
            NavigationView {
                BudgetFormView(budget: budget, isNew: false)
                    .environmentObject(dataManager)
            }
        }
        .sheet(isPresented: $showingAddTotalAmountSheet) {
            NavigationView {
                TotalAmountFormView()
                    .environmentObject(dataManager)
            }
        }
    }
    
    // Total amount display
    private var totalAmountDisplay: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Total Balance")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Text(formatCurrency(dataManager.getTotalAmountAfterExpenses()))
                    .font(.headline)
                    .foregroundColor(AppColors.primary)
            }
            
            Spacer()
            
            Button(action: {
                showingAddTotalAmountSheet = true
            }) {
                Image(systemName: "pencil.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.primary)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Expenses List View
    var expensesListView: some View {
        ZStack {
            VStack {
                // Time filter
                HStack {
                    ForEach(TimeFilter.allCases) { filter in
                        Button(action: {
                            timeFilter = filter
                        }) {
                            Text(filter.rawValue)
                                .font(.subheadline)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    timeFilter == filter ?
                                    AppColors.primary.opacity(0.9) : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    timeFilter == filter ?
                                    Color.white : Color.primary
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Spacer()
                    
                    Text("Total Spend Amount: \(formatCurrency(totalExpenses))")
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.primary)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search expenses", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                if !dataManager.hasTotalAmountSet() {
                    totalAmountEmptyState
                } else if filteredExpenses.isEmpty {
                    EmptyStateView(
                        title: "No Expenses",
                        message: "You haven't added any expenses yet. Tap the + button to add your first expense.",
                        icon: "dollarsign.circle",
                        actionTitle: "Add Expense",
                        action: { showingAddExpenseSheet = true }
                    )
                } else {
                    List {
                        ForEach(filteredExpenses) { expense in
                            ExpenseRow(expense: expense,
                                       onUpdate: { self.editingExpense = $0 },
                                       onDelete: { dataManager.deleteExpense(withId: $0.id) })
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(icon: "plus", action: {
                        if dataManager.hasTotalAmountSet() {
                            showingAddExpenseSheet = true
                        } else {
                            showingAddTotalAmountSheet = true
                        }
                    })
                    .padding()
                }
            }
        }
    }
    
    // Empty state view when total amount is not set
    private var totalAmountEmptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(AppColors.primary)
            
            Text("Set Your Total Amount")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please set your total amount (e.g., salary) to start tracking expenses")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showingAddTotalAmountSheet = true
            }) {
                Text("Add Total Amount")
                    .fontWeight(.semibold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .padding(.top, 10)
        }
        .padding()
    }
    
    // MARK: - Budgets View
    var budgetsView: some View {
        ZStack {
            VStack {
                if dataManager.budgets.isEmpty {
                    EmptyStateView(
                        title: "No Budgets",
                        message: "You haven't set up any budgets yet. Creating a budget helps you manage your spending.",
                        icon: "chart.pie",
                        actionTitle: "Create Budget",
                        action: { showingAddBudgetSheet = true }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(dataManager.budgets) { budget in
                                NavigationLink(destination: BudgetAnalysisView(budget: budget)) {
                                    BudgetCard(budget: budget)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(icon: "plus", action: {
                        showingAddBudgetSheet = true
                    })
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Insights View
    var insightsView: some View {
        ScrollView {
            VStack(spacing: 20) {
                buildTimeFilterSelector()
                buildTotalSpendingCard()
                
                if !dataManager.budgets.isEmpty {
                    buildBudgetSummaryCard()
                }
                
                buildCategoryBreakdownCard()
                buildTipsAndInsightsCard()
            }
            .padding()
        }
    }
    
    private func buildTimeFilterSelector() -> some View {
        HStack {
            ForEach(TimeFilter.allCases) { filter in
                Button(action: {
                    timeFilter = filter
                }) {
                    Text(filter.rawValue)
                        .font(.subheadline)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            timeFilter == filter ?
                            AppColors.primary.opacity(0.9) : Color.gray.opacity(0.2)
                        )
                        .foregroundColor(
                            timeFilter == filter ?
                            Color.white : Color.primary
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func buildTotalSpendingCard() -> some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Your Balance")
                .font(.headline)
                .padding(.leading)
            
            TotalAmountView(showingEditSheet: $showingAddTotalAmountSheet)
        }
    }
    
    private func buildBudgetSummaryCard() -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Budget Overview")
                    .font(.headline)
                
                if !dataManager.budgets.isEmpty {
                    ForEach(Array(dataManager.budgets.prefix(3).enumerated()), id: \.element.id) { index, budget in
                        buildBudgetRow(for: budget)
                        
                        if index < dataManager.budgets.prefix(3).count - 1 {
                            Divider()
                        }
                    }
                    
                    if dataManager.budgets.count > 3 {
                        buildAllBudgetsLink()
                    }
                } else {
                    Text("No budgets available")
                        .foregroundColor(.gray)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
    
    private func buildBudgetRow(for budget: Budget) -> some View {
        let analysis = dataManager.getBudgetAnalysis(for: budget)
        
        return NavigationLink(destination: BudgetAnalysisView(budget: budget)) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(budget.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Text("\(Int(analysis.percentageUsed))% used")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(formatCurrency(analysis.totalSpent)) / \(budget.formattedAmount)")
                        .font(.subheadline)
                        .foregroundColor(analysis.percentageUsed >= 100 ? .red : .primary)
                }
                
                buildProgressBar(for: analysis)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func buildProgressBar(for analysis: BudgetAnalysis) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .frame(height: 6)
                .foregroundColor(Color.gray.opacity(0.2))
                .cornerRadius(3)
            
            let width = max(0, min(1, analysis.percentageUsed / 100)) * (UIScreen.main.bounds.width - 80)
            let color: Color = analysis.percentageUsed >= 100 ? .red : 
                              analysis.percentageUsed >= 80 ? .orange : .green
            
            Rectangle()
                .frame(width: width, height: 6)
                .foregroundColor(color)
                .cornerRadius(3)
        }
    }
    
    private func buildAllBudgetsLink() -> some View {
        NavigationLink(destination: AllBudgetsView()) {
            Text("See All Budgets")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(AppColors.primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func buildCategoryBreakdownCard() -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Spending by Category")
                    .font(.headline)
                
                if groupedByCategory.isEmpty {
                    Text("No data available")
                        .foregroundColor(.gray)
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 20) {
                        buildCategoryChart()
                        buildCategoryLegend()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func buildCategoryChart() -> some View {
        if #available(iOS 16.0, *) {
            Chart {
                ForEach(Array(groupedByCategory.keys), id: \.self) { category in
                    SectorMark(
                        angle: .value("Amount", groupedByCategory[category] ?? 0),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(category.color)
                    .cornerRadius(5)
                    .annotation(position: .overlay) {
                        Text(String(format: "%.0f%%", 
                                    (groupedByCategory[category] ?? 0) / totalExpenses * 100))
                        .font(.caption)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    }
                }
            }
            .frame(height: 220)
        } else {
            Text("Charts only available in iOS 16+")
                .foregroundColor(.gray)
                .frame(height: 220)
        }
    }
    
    private func buildCategoryLegend() -> some View {
        let sortedCategories = groupedByCategory.keys.sorted { groupedByCategory[$1]! < groupedByCategory[$0]! }
        
        return VStack(spacing: 8) {
            ForEach(Array(sortedCategories), id: \.self) { category in
                HStack {
                    Circle()
                        .fill(category.color)
                        .frame(width: 12, height: 12)
                    
                    Text(category.rawValue)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text(formatCurrency(groupedByCategory[category] ?? 0))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func buildTipsAndInsightsCard() -> some View {
        CardView {
            VStack(alignment: .leading, spacing: 15) {
                Text("Tips & Insights")
                    .font(.headline)
                
                VStack(alignment: .leading) {
                    buildHighestSpendingTipView()
                    buildOverBudgetWarningView()
                    buildDailyAverageTipView()
                }
            }
        }
    }
    
    private func buildHighestSpendingTipView() -> some View {
        Group {
            if let topCategory = groupedByCategory.sorted(by: { $0.value > $1.value }).first, totalExpenses > 0 {
                let percentage = Int((topCategory.value / totalExpenses) * 100)
                
                HStack(spacing: 15) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Highest Spending: \(topCategory.key.rawValue)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("You spent \(formatCurrency(topCategory.value)) on \(topCategory.key.rawValue.lowercased()) (\(percentage)% of total)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 5)
            } else {
                EmptyView()
            }
        }
    }
    
    private func buildOverBudgetWarningView() -> some View {
        Group {
            if !dataManager.budgets.isEmpty {
                let overBudgetBudgets = dataManager.budgets.filter { 
                    dataManager.getBudgetAnalysis(for: $0).percentageUsed > 100 
                }
                let overBudgetCount = overBudgetBudgets.count
                
                if overBudgetCount > 0 {
                    HStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text("\(overBudgetCount) budget\(overBudgetCount > 1 ? "s" : "") over limit")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("Check your budget details to adjust spending")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 5)
                } else {
                    EmptyView()
                }
            } else {
                EmptyView()
            }
        }
    }
    
    private func buildDailyAverageTipView() -> some View {
        Group {
            if totalExpenses > 0 {
                dailyAverageContent
            } else {
                EmptyView()
            }
        }
    }
    
    private var dailyAverageContent: some View {
        let daysInPeriod: Double
        switch timeFilter {
        case .week: daysInPeriod = 7
        case .month: daysInPeriod = 30
        case .year: daysInPeriod = 365
        }
        
        let dailyAverage = totalExpenses / daysInPeriod
        
        return HStack(spacing: 15) {
            Image(systemName: "calendar")
                .foregroundColor(.blue)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text("Daily Average: \(formatCurrency(dailyAverage))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("Based on your \(timeFilter.rawValue.lowercased()) spending")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = CURRENCY_SYMBOL
        return formatter.string(from: NSNumber(value: value)) ?? "\(CURRENCY_SYMBOL)\(value)"
    }
}

// MARK: - Expense Row Component
struct ExpenseRow: View {
    let expense: Expense
    var onUpdate: (Expense) -> Void = { _ in }
    var onDelete: (Expense) -> Void = { _ in }
    @State private var isLongPressing = false
    
    var body: some View {
        Button(action: {
            onUpdate(expense)
        }) {
            HStack(spacing: 15) {
                Circle()
                    .fill(expense.category.color)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: expense.category.icon)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(expense.title)
                        .font(.headline)
                    
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(CURRENCY_SYMBOL)\(expense.amount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu(menuItems: {
            Button(action: {
                onUpdate(expense)
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: {
                onDelete(expense)
            }) {
                Label("Delete", systemImage: "trash")
            }
        }, preview: {
            ExpensePreview(expense: expense)
        })
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.3)
                .onEnded { _ in
                    triggerHapticFeedback()
                }
        )
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Expense Preview for Context Menu
struct ExpensePreview: View {
    let expense: Expense
    
    var body: some View {
        VStack(spacing: 15) {
            Circle()
                .fill(expense.category.color)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: expense.category.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 28))
                )
            
            Text(expense.title)
                .font(.headline)
            
            Text("\(CURRENCY_SYMBOL)\(expense.amount, specifier: "%.2f")")
                .font(.title3)
                .foregroundColor(.red)
                .fontWeight(.bold)
                .padding(.horizontal)
          
            Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Budget Card Component
struct BudgetCard: View {
    @EnvironmentObject private var dataManager: DataManager
    let budget: Budget
    
    private var totalSpent: Double {
        let relevantExpenses = dataManager.getRelevantExpensesForBudget(budget)
        return relevantExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var progressPercentage: Double {
        return (totalSpent / budget.amount) * 100
    }
    
    private var remaining: Double {
        return budget.amount - totalSpent
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Budget header view
            budgetHeaderView
            
            // Progress view
            progressView
            
            // Remaining amount view
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(CURRENCY_SYMBOL)\(totalSpent, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(CURRENCY_SYMBOL)\(remaining, specifier: "%.2f")")
                        .font(.subheadline)
                        .foregroundColor(remaining < 0 ? .red : .green)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var budgetHeaderView: some View {
        HStack {
          if budget.category != nil {
                categoryTag
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(budget.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text("\(budget.startDate.formatted(date: .abbreviated, time: .omitted)) - \(budget.endDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(CURRENCY_SYMBOL)\(budget.amount, specifier: "%.2f")")
                .font(.headline)
        }
    }
    
    private var categoryTag: some View {
        ZStack {
            Rectangle()
                .fill(budget.category?.color ?? .gray)
                .frame(width: 4)
                .cornerRadius(2)
        }
        .frame(width: 4, height: 35)
        .padding(.trailing, 8)
    }
    
    private var progressView: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(
                            progressPercentage > 100 
                            ? Color.red 
                            : (progressPercentage > 80 ? Color.orange : Color.blue)
                        )
                        .frame(width: min(CGFloat(progressPercentage / 100) * geometry.size.width, geometry.size.width), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
            
            HStack {
                Text("\(Int(progressPercentage))% used")
                    .font(.caption)
                    .foregroundColor(
                        progressPercentage > 100 
                        ? .red 
                        : (progressPercentage > 80 ? .orange : .secondary)
                    )
                
                Spacer()
            }
        }
    }
}

// MARK: - Expense Form
struct ExpenseFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var title: String
    @State private var amount: Double
    @State private var date: Date
    @State private var notes: String
    @State private var category: ExpenseCategory
    @State private var isRecurring: Bool
    @State private var recurringFrequency: RecurringFrequency?
    @State private var showInsufficientFundsAlert: Bool = false
    
    let isNew: Bool
    private let expenseID: UUID
    
    init(expense: Expense, isNew: Bool) {
        self._title = State(initialValue: expense.title)
        self._amount = State(initialValue: expense.amount)
        self._date = State(initialValue: expense.date)
        self._notes = State(initialValue: expense.notes)
        self._category = State(initialValue: expense.category)
        self._isRecurring = State(initialValue: expense.isRecurring)
        self._recurringFrequency = State(initialValue: expense.recurringFrequency)
        self.isNew = isNew
        self.expenseID = expense.id
    }
    
    // String binding for amount input
    private var amountString: Binding<String> {
        Binding<String>(
            get: { String(format: "%.2f", self.amount) },
            set: {
                if let value = Double($0.replacingOccurrences(of: ",", with: ".")) {
                    self.amount = value
                }
            }
        )
    }
    
    var body: some View {
        Form {
            detailsSection
            additionalInfoSection
            recurringSection
        }
        .navigationTitle(isNew ? "New Expense" : "Edit Expense")
        .navigationBarItems(
            leading: cancelButton,
            trailing: saveButton
        )
        .alert(isPresented: $showInsufficientFundsAlert) {
            Alert(
                title: Text("Insufficient Funds"),
                message: Text("You don't have enough funds to cover this expense. Would you like to add it anyway?"),
                primaryButton: .default(Text("Add Anyway")) {
                    saveExpenseWithoutCheck()
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextField("Title", text: $title)
            
            HStack {
                Text(CURRENCY_SYMBOL)
                TextField("Amount", text: amountString)
                    .keyboardType(.decimalPad)
            }
            
            DatePicker("Date", selection: $date, displayedComponents: [.date])
            
            categoryPicker
        }
    }
    
    private var categoryPicker: some View {
        Picker("Category", selection: $category) {
            ForEach(ExpenseCategory.allCases) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.rawValue)
                }.tag(category)
            }
        }
    }
    
    private var additionalInfoSection: some View {
        Section(header: Text("Additional Information")) {
            VStack(alignment: .leading) {
                Text("Notes")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
    }
    
    private var recurringSection: some View {
        Section(header: Text("Recurring Expense")) {
            Toggle("Recurring", isOn: $isRecurring)
            
            if isRecurring {
                frequencyPicker
            }
        }
    }
    
    private var frequencyPicker: some View {
        Picker("Frequency", selection: $recurringFrequency) {
            Text("Select").tag(nil as RecurringFrequency?)
            ForEach(RecurringFrequency.allCases) { frequency in
                Text(frequency.rawValue).tag(frequency as RecurringFrequency?)
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var saveButton: some View {
        Button(isNew ? "Add" : "Save") {
            // Check if we have enough funds when adding a new expense
            if isNew && dataManager.hasTotalAmountSet() {
              _ = dataManager.getTotalAmountAfterExpenses()
                let existingTotal = dataManager.expenses.reduce(0) { $0 + $1.amount }
                let newTotal = existingTotal + amount
                
                if dataManager.totalAmount?.amount ?? 0 < newTotal {
                    showInsufficientFundsAlert = true
                    return
                }
            }
            
            saveExpenseWithoutCheck()
            presentationMode.wrappedValue.dismiss()
        }
        .disabled(title.isEmpty || amount <= 0)
    }
    
    private func saveExpenseWithoutCheck() {
        let expense = Expense(
            id: expenseID,
            title: title,
            amount: amount,
            date: date,
            category: category,
            notes: notes,
            isRecurring: isRecurring,
            recurringFrequency: isRecurring ? recurringFrequency : nil,
            createdAt: isNew ? Date() : (dataManager.expenses.first(where: { $0.id == expenseID })?.createdAt ?? Date())
        )
        
        if isNew {
            dataManager.addExpense(expense)
        } else {
            dataManager.updateExpense(expense)
        }
    }
}

// MARK: - Budget Form
struct BudgetFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var name: String
    @State private var amount: Double
    @State private var hasCategory: Bool
    @State private var category: ExpenseCategory?
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedPeriod: BudgetPeriod = .custom
    
    enum BudgetPeriod: String, CaseIterable, Identifiable {
        case weekly = "Weekly"
        case monthly = "Monthly"
        case quarterly = "Quarterly"
        case yearly = "Yearly"
        case custom = "Custom"
        
        var id: String { self.rawValue }
    }
    
    let isNew: Bool
    private let budgetID: UUID
    
    init(budget: Budget, isNew: Bool) {
        self._name = State(initialValue: budget.name)
        self._amount = State(initialValue: budget.amount)
        self._hasCategory = State(initialValue: budget.category != nil)
        self._category = State(initialValue: budget.category)
        self._startDate = State(initialValue: budget.startDate)
        self._endDate = State(initialValue: budget.endDate)
        self.isNew = isNew
        self.budgetID = budget.id
    }
    
    // String binding for amount input
    private var amountString: Binding<String> {
        Binding<String>(
            get: { String(format: "%.2f", self.amount) },
            set: {
                if let value = Double($0.replacingOccurrences(of: ",", with: ".")) {
                    self.amount = value
                }
            }
        )
    }
    
    private func updateDateRange(for period: BudgetPeriod) {
        let calendar = Calendar.current
        let today = Date()
        
        switch period {
        case .weekly:
            // Start of current week to end of current week
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            startDate = startOfWeek
            endDate = calendar.date(byAdding: .day, value: 6, to: startOfWeek)!
            
        case .monthly:
            // Start of current month to end of current month
            let components = calendar.dateComponents([.year, .month], from: today)
            startDate = calendar.date(from: components)!
            endDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startDate)!
            
        case .quarterly:
            // Start of current quarter to end of quarter (3 months)
            let month = calendar.component(.month, from: today)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            var components = calendar.dateComponents([.year], from: today)
            components.month = quarterStartMonth
            components.day = 1
            startDate = calendar.date(from: components)!
            endDate = calendar.date(byAdding: DateComponents(month: 3, day: -1), to: startDate)!
            
        case .yearly:
            // Start of current year to end of current year
            var components = calendar.dateComponents([.year], from: today)
            components.month = 1
            components.day = 1
            startDate = calendar.date(from: components)!
            components.month = 12
            components.day = 31
            endDate = calendar.date(from: components)!
            
        case .custom:
            // Leave dates as they are
            break
        }
    }
    
    var body: some View {
        Form {
            detailsSection
            timePeriodSection
            categorySection
        }
        .navigationTitle(isNew ? "New Budget" : "Edit Budget")
        .navigationBarItems(
            leading: cancelButton,
            trailing: saveButton
        )
    }
    
    private var detailsSection: some View {
        Section(header: Text("Details")) {
            TextField("Name", text: $name)
            
            HStack {
                Text(CURRENCY_SYMBOL)
                TextField("Amount", text: amountString)
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    private var timePeriodSection: some View {
        Section(header: Text("Time Period")) {
            periodPicker
            startDatePicker
            endDatePicker
            durationInfo
            dailyAllowanceInfo
        }
    }
    
    private var periodPicker: some View {
        Picker("Budget Period", selection: $selectedPeriod) {
            ForEach(BudgetPeriod.allCases) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .onChange(of: selectedPeriod) { newValue in
            updateDateRange(for: newValue)
        }
    }
    
    private var startDatePicker: some View {
        DatePicker("Start Date", selection: $startDate, displayedComponents: [.date])
            .disabled(selectedPeriod != .custom)
    }
    
    private var endDatePicker: some View {
        DatePicker("End Date", selection: $endDate, displayedComponents: [.date])
            .disabled(selectedPeriod != .custom)
            .onChange(of: startDate) { newValue in
                if endDate < newValue {
                    endDate = newValue
                }
            }
    }
    
    @ViewBuilder
    private var durationInfo: some View {
        if let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day {
            HStack {
                Text("Duration")
                Spacer()
                Text("\(days + 1) days")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var dailyAllowanceInfo: some View {
        if let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day, days > 0 {
            let dailyAmount = amount / Double(days + 1)
            HStack {
                Text("Daily Allowance")
                Spacer()
                Text(formatCurrency(dailyAmount))
                    .foregroundColor(AppColors.primary)
            }
        }
    }
    
    private var categorySection: some View {
        Section(header: Text("Category")) {
            Toggle("Specific Category", isOn: $hasCategory)
            
            if hasCategory {
                categoryPicker
            }
        }
    }
    
    private var categoryPicker: some View {
        Picker("Category", selection: $category) {
            Text("Select").tag(nil as ExpenseCategory?)
            ForEach(ExpenseCategory.allCases) { category in
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.rawValue)
                }.tag(category as ExpenseCategory?)
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private var saveButton: some View {
        Button(isNew ? "Add" : "Save") {
            saveBudget()
            presentationMode.wrappedValue.dismiss()
        }
        .disabled(name.isEmpty || amount <= 0 || (hasCategory && category == nil))
    }
    
    private func saveBudget() {
        let budget = Budget(
            id: budgetID,
            name: name,
            amount: amount,
            category: hasCategory ? category : nil,
            startDate: startDate,
            endDate: endDate,
            createdAt: isNew ? Date() : (dataManager.budgets.first(where: { $0.id == budgetID })?.createdAt ?? Date())
        )
        
        if isNew {
            dataManager.addBudget(budget)
        } else {
            dataManager.updateBudget(budget)
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = CURRENCY_SYMBOL
        return formatter.string(from: NSNumber(value: value)) ?? "\(CURRENCY_SYMBOL)\(value)"
    }
}

// MARK: - Total Amount Form
struct TotalAmountFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var amount: String
    @State private var description: String
    
    init() {
        if let totalAmount = DataManager().totalAmount {
            self._amount = State(initialValue: String(format: "%.2f", totalAmount.amount))
            self._description = State(initialValue: totalAmount.description)
        } else {
            self._amount = State(initialValue: "")
            self._description = State(initialValue: "Total Balance")
        }
    }
    
    var body: some View {
        Form {
            Section(header: Text("Amount Details")) {
                HStack {
                    Text(CURRENCY_SYMBOL)
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                }
                
                TextField("Description (optional)", text: $description)
            }
            
            Section(header: Text("Summary")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("This amount will be used as your starting balance.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    if let existingAmount = dataManager.totalAmount?.amount,
                       let newAmount = Double(amount.replacingOccurrences(of: ",", with: ".")),
                       existingAmount != newAmount {
                        Text("Note: Changing your total amount will not affect your existing expenses.")
                            .font(.footnote)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .navigationTitle("Set Total Amount")
        .navigationBarItems(
            leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            },
            trailing: Button("Save") {
                if let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) {
                    dataManager.updateTotalAmount(amountValue, description: description)
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .disabled(amount.isEmpty || Double(amount.replacingOccurrences(of: ",", with: ".")) == nil)
        )
    }
}

// MARK: - Preview
struct ExpensesView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExpensesView()
                .environmentObject(DataManager())
        }
    }
}

// Add a circular progress view for visual representation
struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear, value: progress)
            
            Text("\(Int(progress * 100))%")
                .font(.system(size: 10))
                .fontWeight(.bold)
        }
    }
}

struct TotalAmountView: View {
    @EnvironmentObject private var dataManager: DataManager
    @Binding var showingEditSheet: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Total Amount")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if let totalAmount = dataManager.totalAmount {
                        Text("\(CURRENCY_SYMBOL)\(totalAmount.amount, specifier: "%.2f")")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        if !totalAmount.description.isEmpty {
                            Text(totalAmount.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Not set")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    showingEditSheet = true
                }) {
                    Image(systemName: "pencil")
                        .padding(10)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                        .foregroundColor(.blue)
                }
            }
            
            if dataManager.hasTotalAmountSet() {
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(CURRENCY_SYMBOL)\(dataManager.getSpentAmount(), specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(CURRENCY_SYMBOL)\(dataManager.getTotalAmountAfterExpenses(), specifier: "%.2f")")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                    
                    Spacer()
                    
                    CircularProgressView(
                        progress: min(1.0, dataManager.getSpentPercentage() / 100),
                        color: dataManager.getSpentPercentage() > 90 ? .red : .blue
                    )
                    .frame(width: 40, height: 40)
                }
                .padding(.top, 10)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - All Budgets View
struct AllBudgetsView: View {
    @EnvironmentObject private var dataManager: DataManager
    
    var body: some View {
        List {
            ForEach(dataManager.budgets) { budget in
                NavigationLink(destination: BudgetAnalysisView(budget: budget)) {
                    Text(budget.name)
                }
            }
        }
        .navigationTitle("All Budgets")
    }
} 
