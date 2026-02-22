//
//  Flash_CardApp.swift
//  Flash-Card
//
//  Created by WANNASINGH KHANSOPHON on 21/2/2569 BE.
//

import SwiftUI
import CoreData

@main
struct Flash_CardApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var sessionStore = SessionStore.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(sessionStore)
                .environmentObject(themeManager)
        }
    }
}
