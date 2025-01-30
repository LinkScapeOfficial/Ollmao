//
//  OllmaoApp.swift
//  Ollmao
//
//  Created by Zigao Wang on 1/28/25.
//

import SwiftUI

@main
struct OllmaoApp: App {
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var viewModel: ChatViewModel
    
    init() {
        let manager = ConversationManager()
        _conversationManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversationManager: manager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
