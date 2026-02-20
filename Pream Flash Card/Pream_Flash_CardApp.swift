//
//  Pream_Flash_CardApp.swift
//  Pream Flash Card
//
//  Created by WANNASINGH KHANSOPHON on 21/2/2569 BE.
//

import SwiftUI
import CoreData

@main
struct Pream_Flash_CardApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
