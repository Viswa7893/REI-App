import SwiftUI

struct RemindersView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var showingAddReminderSheet = false
    @State private var editingReminder: Reminder? = nil
    @State private var selectedFilter: ReminderFilter = .all
    @State private var searchText = ""
    
    enum ReminderFilter {
        case all, today, upcoming, completed
        
        var title: String {
            switch self {
            case .all: return "All"
            case .today: return "Today"
            case .upcoming: return "Upcoming"
            case .completed: return "Completed"
            }
        }
    }
    
    var filteredReminders: [Reminder] {
        let filtered = dataManager.reminders.filter { reminder in
            if searchText.isEmpty {
                return true
            } else {
                return reminder.title.localizedCaseInsensitiveContains(searchText) ||
                    reminder.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all:
            return filtered
        case .today:
            let today = Calendar.current.startOfDay(for: Date())
            return filtered.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: today) }
        case .upcoming:
            let today = Calendar.current.startOfDay(for: Date())
            return filtered.filter { !$0.isCompleted && $0.dueDate > today }
        case .completed:
            return filtered.filter { $0.isCompleted }
        }
    }
    
    var body: some View {
        ZStack {
            VStack {
                // Filter tabs
                HStack {
                    ForEach([ReminderFilter.all, .today, .upcoming, .completed], id: \.title) { filter in
                        Button(action: {
                            selectedFilter = filter
                        }) {
                            VStack {
                                Text(filter.title)
                                    .font(.subheadline)
                                    .fontWeight(selectedFilter == filter ? .bold : .regular)
                                
                                if selectedFilter == filter {
                                    Rectangle()
                                        .frame(height: 3)
                                        .foregroundColor(AppColors.primary)
                                } else {
                                    Rectangle()
                                        .frame(height: 3)
                                        .foregroundColor(.clear)
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 8)
                
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    TextField("Search reminders", text: $searchText)
                        .padding(8)
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if filteredReminders.isEmpty {
                    EmptyStateView(
                        title: "No Reminders",
                        message: "You don't have any reminders in this category. Tap the + button to create a new reminder.",
                        icon: "bell.badge",
                        actionTitle: "Create Reminder",
                        action: { showingAddReminderSheet = true }
                    )
                } else {
                    List {
                        ForEach(filteredReminders) { reminder in
                            ReminderRow(reminder: reminder)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editingReminder = reminder
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        dataManager.deleteReminder(withId: reminder.id)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                    
                                    Button {
                                        var updatedReminder = reminder
                                        updatedReminder.isCompleted.toggle()
                                        dataManager.updateReminder(updatedReminder)
                                    } label: {
                                        Label(reminder.isCompleted ? "Incomplete" : "Complete", 
                                              systemImage: reminder.isCompleted ? "xmark.circle" : "checkmark.circle")
                                    }
                                    .tint(AppColors.primary)
                                }
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
                        showingAddReminderSheet = true
                    })
                    .padding()
                }
            }
        }
        .navigationTitle("Reminders")
        .sheet(isPresented: $showingAddReminderSheet) {
            ReminderFormView(
                reminder: Reminder(title: "", dueDate: Date()),
                isNew: true
            )
        }
        .sheet(item: $editingReminder) { reminder in
            ReminderFormView(
                reminder: reminder,
                isNew: false
            )
        }
    }
}

struct ReminderRow: View {
    let reminder: Reminder
    
    var body: some View {
        HStack {
            Image(systemName: reminder.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(reminder.isCompleted ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.title)
                    .font(.headline)
                    .strikethrough(reminder.isCompleted)
                    .foregroundColor(reminder.isCompleted ? .gray : .primary)
                
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                    
                    Text(formatDate(reminder.dueDate))
                        .font(.caption)
                    
                    if !reminder.isCompleted && reminder.isOverdue {
                        Text("Overdue")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if !reminder.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                    }
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            HStack {
                Image(systemName: reminder.priority.icon)
                    .foregroundColor(reminder.priority.color)
                    .font(.caption)
                
                Circle()
                    .fill(reminder.category.color)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Today, \(formatter.string(from: date))"
        } else if Calendar.current.isDateInTomorrow(date) {
            formatter.dateStyle = .none
            formatter.timeStyle = .short
            return "Tomorrow, \(formatter.string(from: date))"
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
}

// Form to add and edit reminders
struct ReminderFormView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var title: String
    @State private var notes: String
    @State private var dueDate: Date
    @State private var isCompleted: Bool
    @State private var priority: ReminderPriority
    @State private var category: ReminderCategory
    
    let isNew: Bool
    private let reminderID: UUID
    
    init(reminder: Reminder, isNew: Bool) {
        self._title = State(initialValue: reminder.title)
        self._notes = State(initialValue: reminder.notes)
        self._dueDate = State(initialValue: reminder.dueDate)
        self._isCompleted = State(initialValue: reminder.isCompleted)
        self._priority = State(initialValue: reminder.priority)
        self._category = State(initialValue: reminder.category)
        self.isNew = isNew
        self.reminderID = reminder.id
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details")) {
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading) {
                        Text("Notes")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                }
                
                Section(header: Text("Due Date")) {
                    DatePicker("Due Date", selection: $dueDate)
                }
                
                Section(header: Text("Status")) {
                    Toggle("Completed", isOn: $isCompleted)
                }
                
                Section(header: Text("Priority")) {
                    Picker("Priority", selection: $priority) {
                        ForEach(ReminderPriority.allCases) { priority in
                            Label(
                                title: { Text(priority.rawValue) },
                                icon: { Image(systemName: priority.icon).foregroundColor(priority.color) }
                            ).tag(priority)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Category")) {
                    Picker("Category", selection: $category) {
                        ForEach(ReminderCategory.allCases) { category in
                            HStack {
                                Circle()
                                    .fill(category.color)
                                    .frame(width: 10, height: 10)
                                Text(category.rawValue)
                            }.tag(category)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "New Reminder" : "Edit Reminder")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button(isNew ? "Add" : "Save") {
                    saveReminder()
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(title.isEmpty)
            )
        }
    }
    
    private func saveReminder() {
        let reminder = Reminder(
            id: reminderID,
            title: title,
            notes: notes,
            dueDate: dueDate,
            isCompleted: isCompleted,
            priority: priority,
            category: category,
            createdAt: isNew ? Date() : (dataManager.reminders.first(where: { $0.id == reminderID })?.createdAt ?? Date()),
            lastModified: Date()
        )
        
        if isNew {
            dataManager.addReminder(reminder)
        } else {
            dataManager.updateReminder(reminder)
        }
        
        // Schedule notification for the reminder
        NotificationManager.shared.scheduleReminderNotification(for: reminder)
    }
}

// Preview for UI Development
struct RemindersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RemindersView()
                .environmentObject(DataManager())
        }
    }
} 