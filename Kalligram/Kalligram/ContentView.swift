//
//  ContentView.swift
//  Kalligram
//
//  Created by Ryan Trumble on 8/2/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainWindowView()
    }
}

#Preview {
    ContentView()
        .environment(AppState())
        .environment(AppViewModel())
        .modelContainer(for: [
            Document.self,
            Project.self,
            DocumentSection.self,
            Template.self,
            Citation.self,
            Comment.self,
            Version.self,
            ProjectBranch.self,
            ProjectSnapshot.self,
            SnapshotDocument.self,
            AIAction.self,
            ResearchNote.self,
            UserSettings.self
        ])
}
