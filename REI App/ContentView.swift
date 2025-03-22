//
//  ContentView.swift
//  REI App
//
//  Created by Durga Viswanadh on 22/03/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var dataManager: DataManager
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Reminders Tab
            NavigationView {
                RemindersView()
            }
            .tabItem {
                Label("Reminders", systemImage: "checklist")
            }
            .tag(0)
            
            // Expenses Tab
            NavigationView {
                ExpensesView()
            }
            .tabItem {
                Label("Expenses", systemImage: "creditcard")
            }
            .tag(1)
            
            // Interest Calculator Tab
            NavigationView {
                InterestCalculatorView()
            }
            .tabItem {
                Label("Calculator", systemImage: "percent")
            }
            .tag(2)
        }
        .accentColor(AppColors.primary)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DataManager())
    }
}
