import Foundation

enum InterestType: String, CaseIterable, Identifiable, Codable {
    case simple = "Simple Interest"
    case compound = "Compound Interest"
    
    var id: String { self.rawValue }
}

enum CompoundingFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case semiAnnually = "Semi-Annually"
    case annually = "Annually"
    
    var id: String { self.rawValue }
    
    var periodsPerYear: Double {
        switch self {
        case .daily: return 365
        case .monthly: return 12
        case .quarterly: return 4
        case .semiAnnually: return 2
        case .annually: return 1
        }
    }
}

struct InterestCalculation: Identifiable, Codable {
    var id = UUID()
    var name: String
    var principal: Double
    var rate: Double // Annual interest rate in percentage (e.g., 5.0 for 5%)
    var time: Double // Time in years
    var interestType: InterestType
    var compoundingFrequency: CompoundingFrequency?
    var createdAt: Date = Date()
    
    var interestAmount: Double {
        switch interestType {
        case .simple:
            return calculateSimpleInterest()
        case .compound:
            return calculateCompoundInterest()
        }
    }
    
    var totalAmount: Double {
        return principal + interestAmount
    }
    
    private func calculateSimpleInterest() -> Double {
        return principal * (rate / 100) * time
    }
    
    private func calculateCompoundInterest() -> Double {
        guard let frequency = compoundingFrequency else { return 0 }
        let r = rate / 100
        let n = frequency.periodsPerYear
        let nt = n * time
        
        let amount = principal * pow((1 + (r / n)), nt)
        return amount - principal
    }
    
    func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
} 