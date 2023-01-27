//
//  Blue4App.swift
//  Blue4
//
//  Created by Athul Joseph on 27/01/23.
//

import SwiftUI

@main
struct Blue4App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
