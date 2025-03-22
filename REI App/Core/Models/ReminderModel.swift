import Foundation
import SwiftUI

enum ReminderPriority: String, CaseIterable, Identifiable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "arrow.down.circle.fill"
        case .medium: return "equal.circle.fill"
        case .high: return "exclamationmark.circle.fill"
        }
    }
}

enum ReminderCategory: String, CaseIterable, Identifiable, Codable {
    case personal = "Personal"
    case work = "Work"
    case health = "Health"
    case finance = "Finance"
    case other = "Other"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .personal: return Color.blue
        case .work: return Color.purple
        case .health: return Color.green
        case .finance: return Color.yellow
        case .other: return Color.gray
        }
    }
    
    var icon: String {
        switch self {
        case .personal: return "person.fill"
        case .work: return "briefcase.fill"
        case .health: return "heart.fill"
        case .finance: return "dollarsign.circle.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

struct Reminder: Identifiable, Codable {
    var id = UUID()
    var title: String
    var notes: String = ""
    var dueDate: Date
    var isCompleted: Bool = false
    var priority: ReminderPriority = .medium
    var category: ReminderCategory = .personal
    var createdAt: Date = Date()
    var lastModified: Date = Date()
    
    var isOverdue: Bool {
        return !isCompleted && dueDate < Date()
    }
} 