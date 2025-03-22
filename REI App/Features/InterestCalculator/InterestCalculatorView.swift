import SwiftUI

struct InterestCalculatorView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTab = 0
    @State private var showingAddCalculationSheet = false
    @State private var editingCalculation: InterestCalculation? = nil
    
    var body: some View {
        VStack {
            // Segment control for tab selection
            SegmentedPicker(
                items: ["Calculator", "Saved Calculations"],
                selectedIndex: $selectedTab
            )
            .padding()
            
            // Content based on selected tab
            if selectedTab == 0 {
                // Calculator tab
                InterestCalculatorForm()
            } else {
                // Saved Calculations tab
                savedCalculationsView
            }
        }
        .navigationTitle("Interest Calculator")
        .sheet(item: $editingCalculation) { calculation in
            InterestCalculatorDetailView(calculation: calculation)
        }
    }
    
    var savedCalculationsView: some View {
        ZStack {
            if dataManager.interestCalculations.isEmpty {
                EmptyStateView(
                    title: "No Saved Calculations",
                    message: "You haven't saved any interest calculations yet. Use the calculator to create and save new calculations.",
                    icon: "percent",
                    actionTitle: "Go to Calculator",
                    action: { selectedTab = 0 }
                )
            } else {
                List {
                    ForEach(dataManager.interestCalculations.sorted(by: { $0.createdAt > $1.createdAt })) { calculation in
                        InterestCalculationRow(calculation: calculation)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingCalculation = calculation
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    dataManager.deleteInterestCalculation(withId: calculation.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
    }
}

struct InterestCalculationRow: View {
    let calculation: InterestCalculation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "percent.circle.fill")
                    .foregroundColor(calculation.interestType == .simple ? .blue : .purple)
                    .font(.title3)
                
                Text(calculation.name)
                    .font(.headline)
                
                Spacer()
                
                Text(calculation.interestType.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(calculation.interestType == .simple ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                    .foregroundColor(calculation.interestType == .simple ? .blue : .purple)
                    .cornerRadius(8)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Principal")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(calculation.formattedAmount(calculation.principal))
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(String(format: "%.2f", calculation.rate))%")
                        .font(.subheadline)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(String(format: "%.1f", calculation.time)) years")
                        .font(.subheadline)
                }
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Interest")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(calculation.formattedAmount(calculation.interestAmount))
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(calculation.formattedAmount(calculation.totalAmount))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct InterestCalculatorForm: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var name = ""
    @State private var principal = ""
    @State private var rate = ""
    @State private var time = ""
    @State private var interestType: InterestType = .simple
    @State private var compoundingFrequency: CompoundingFrequency = .annually
    @State private var showingResults = false
    @State private var showingSavePrompt = false
    @State private var currentCalculation: InterestCalculation?
    
    var isFormValid: Bool {
        let principalValue = Double(principal.replacingOccurrences(of: ",", with: ".")) ?? 0
        let rateValue = Double(rate.replacingOccurrences(of: ",", with: ".")) ?? 0
        let timeValue = Double(time.replacingOccurrences(of: ",", with: ".")) ?? 0
        
        return principalValue > 0 && rateValue > 0 && timeValue > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Type selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Interest Type")
                        .font(.headline)
                    
                    Picker("Interest Type", selection: $interestType) {
                        ForEach(InterestType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: interestType) { _ in
                        showingResults = false
                    }
                }
                .padding(.horizontal)
                
                // Input form
                CardView(backgroundColor: Color(.systemBackground)) {
                    VStack(alignment: .leading, spacing: 16) {
                        CustomTextField(
                            title: "Name (Optional)",
                            placeholder: "e.g., Home Loan, Investment",
                            text: $name,
                            leadingIcon: "pencil"
                        )
                        
                        CustomTextField(
                            title: "Principal Amount",
                            placeholder: "e.g., 10000",
                            text: $principal,
                            keyboardType: .decimalPad,
                            leadingIcon: "dollarsign.circle"
                        )
                        
                        CustomTextField(
                            title: "Annual Interest Rate (%)",
                            placeholder: "e.g., 5.5",
                            text: $rate,
                            keyboardType: .decimalPad,
                            leadingIcon: "percent"
                        )
                        
                        CustomTextField(
                            title: "Time (Years)",
                            placeholder: "e.g., 3",
                            text: $time,
                            keyboardType: .decimalPad,
                            leadingIcon: "calendar"
                        )
                        
                        if interestType == .compound {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Compounding Frequency")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Picker("Compounding Frequency", selection: $compoundingFrequency) {
                                    ForEach(CompoundingFrequency.allCases) { frequency in
                                        Text(frequency.rawValue).tag(frequency)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                        }
                        
                        CustomButton(
                            title: "Calculate",
                            action: calculateInterest,
                            isDisabled: !isFormValid
                        )
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                // Results
                if showingResults, let calculation = currentCalculation {
                    CardView(backgroundColor: Color(.systemBackground)) {
                        VStack(spacing: 16) {
                            Text("Results")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 20) {
                                resultRow(
                                    title: "Principal Amount",
                                    value: calculation.formattedAmount(calculation.principal),
                                    icon: "dollarsign.circle",
                                    color: .blue
                                )
                                
                                resultRow(
                                    title: "Interest Amount",
                                    value: calculation.formattedAmount(calculation.interestAmount),
                                    icon: "plus.circle",
                                    color: .green
                                )
                                
                                Divider()
                                
                                resultRow(
                                    title: "Total Amount",
                                    value: calculation.formattedAmount(calculation.totalAmount),
                                    icon: "equal.circle",
                                    color: .purple,
                                    isLarge: true
                                )
                            }
                            
                            CustomButton(
                                title: "Save Calculation",
                                action: { showingSavePrompt = true },
                                style: .outline,
                                icon: "square.and.arrow.down"
                            )
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .alert("Save Calculation", isPresented: $showingSavePrompt) {
            TextField("Name", text: $name)
                .autocapitalization(.words)
            
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveCalculation()
            }
        } message: {
            Text("Enter a name to save this calculation for future reference.")
        }
    }
    
    private func resultRow(title: String, value: String, icon: String, color: Color, isLarge: Bool = false) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(isLarge ? .title3 : .body)
            
            Text(title)
                .font(isLarge ? .headline : .subheadline)
            
            Spacer()
            
            Text(value)
                .font(isLarge ? .title3.bold() : .headline)
                .foregroundColor(isLarge ? color : .primary)
        }
    }
    
    private func calculateInterest() {
        guard
            let principalValue = Double(principal.replacingOccurrences(of: ",", with: ".")),
            let rateValue = Double(rate.replacingOccurrences(of: ",", with: ".")),
            let timeValue = Double(time.replacingOccurrences(of: ",", with: "."))
        else { return }
        
        let calculationName = name.isEmpty ? "Calculation \(Date().formatted(date: .abbreviated, time: .shortened))" : name
        
        currentCalculation = InterestCalculation(
            name: calculationName,
            principal: principalValue,
            rate: rateValue,
            time: timeValue,
            interestType: interestType,
            compoundingFrequency: interestType == .compound ? compoundingFrequency : nil
        )
        
        withAnimation {
            showingResults = true
        }
    }
    
    private func saveCalculation() {
        guard let calculation = currentCalculation else { return }
        
        // Update the name if it was changed in the alert
        let updatedCalculation = InterestCalculation(
            id: calculation.id,
            name: name.isEmpty ? calculation.name : name,
            principal: calculation.principal,
            rate: calculation.rate,
            time: calculation.time,
            interestType: calculation.interestType,
            compoundingFrequency: calculation.compoundingFrequency
        )
        
        dataManager.addInterestCalculation(updatedCalculation)
    }
}

struct InterestCalculatorDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    let calculation: InterestCalculation
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text(calculation.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text(calculation.interestType.rawValue)
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(calculation.interestType == .simple ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                            .foregroundColor(calculation.interestType == .simple ? .blue : .purple)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                    
                    // Input parameters
                    CardView(backgroundColor: Color(.systemBackground)) {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Input Parameters")
                                .font(.headline)
                            
                            parameterRow(title: "Principal Amount", value: calculation.formattedAmount(calculation.principal))
                            parameterRow(title: "Interest Rate", value: "\(String(format: "%.2f", calculation.rate))% per annum")
                            parameterRow(title: "Time Period", value: "\(String(format: "%.1f", calculation.time)) years")
                            
                            if calculation.interestType == .compound, let frequency = calculation.compoundingFrequency {
                                parameterRow(title: "Compounding Frequency", value: frequency.rawValue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Results visualization
                    CardView(backgroundColor: Color(.systemBackground)) {
                        VStack(spacing: 16) {
                            Text("Results")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Pie chart
                            ZStack {
                                Circle()
                                    .trim(from: 0, to: CGFloat(calculation.principal / calculation.totalAmount))
                                    .stroke(Color.blue, lineWidth: 20)
                                    .frame(width: 200, height: 200)
                                    .rotationEffect(.degrees(-90))
                                
                                Circle()
                                    .trim(from: CGFloat(calculation.principal / calculation.totalAmount), to: 1)
                                    .stroke(Color.green, lineWidth: 20)
                                    .frame(width: 200, height: 200)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("Total")
                                        .font(.headline)
                                    
                                    Text(calculation.formattedAmount(calculation.totalAmount))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                }
                            }
                            .padding(.vertical)
                            
                            // Legend
                            HStack(spacing: 20) {
                                HStack {
                                    Circle()
                                        .fill(Color.blue)
                                        .frame(width: 12, height: 12)
                                    
                                    Text("Principal")
                                        .font(.caption)
                                }
                                
                                HStack {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 12, height: 12)
                                    
                                    Text("Interest")
                                        .font(.caption)
                                }
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            // Breakdown
                            Group {
                                resultRow(
                                    title: "Principal Amount",
                                    value: calculation.formattedAmount(calculation.principal),
                                    percentage: String(format: "%.1f%%", (calculation.principal / calculation.totalAmount) * 100),
                                    color: .blue
                                )
                                
                                resultRow(
                                    title: "Interest Earned",
                                    value: calculation.formattedAmount(calculation.interestAmount),
                                    percentage: String(format: "%.1f%%", (calculation.interestAmount / calculation.totalAmount) * 100),
                                    color: .green
                                )
                                
                                Divider()
                                
                                resultRow(
                                    title: "Total Amount",
                                    value: calculation.formattedAmount(calculation.totalAmount),
                                    percentage: "100%",
                                    color: .purple,
                                    isBold: true
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.bottom, 40)
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private func parameterRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
        }
    }
    
    private func resultRow(title: String, value: String, percentage: String, color: Color, isBold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isBold ? .headline : .subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(value)
                    .font(isBold ? .headline : .subheadline)
                    .fontWeight(isBold ? .bold : .regular)
                
                Text(percentage)
                    .font(.caption)
                    .foregroundColor(color)
            }
        }
    }
}

// Preview
struct InterestCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InterestCalculatorView()
                .environmentObject(DataManager())
        }
    }
} 