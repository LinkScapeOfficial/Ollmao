//
//  ContentView.swift
//  Ollmao
//
//  Created by Zigao Wang on 1/28/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $viewModel.selectedConversationId) {
                Button(action: { viewModel.newConversation() }) {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
                .buttonStyle(.borderless)
                .padding(.vertical, 8)
                
                if !viewModel.conversations.isEmpty {
                    Section("Chats") {
                        ForEach(viewModel.conversations) { conversation in
                            NavigationLink(value: conversation.id) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .lineLimit(1)
                                    Text(conversation.model)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.deleteConversation(conversation.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Ollmao")
            .toolbar {
                Menu {
                    Picker("Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                } label: {
                    Label(viewModel.selectedModel, systemImage: "cpu")
                }
            }
        } detail: {
            if let conversation = viewModel.selectedConversation {
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(conversation.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: conversation.messages.count) { oldValue, newValue in
                            if let lastMessage = conversation.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Input area
                    HStack(spacing: 12) {
                        TextField("Type your message...", text: $viewModel.inputMessage, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(12)
                            .focused($isInputFocused)
                            .disabled(viewModel.isLoading)
                            .onSubmit {
                                Task {
                                    await viewModel.sendMessage()
                                }
                            }
                        
                        Button {
                            Task {
                                await viewModel.sendMessage()
                            }
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(viewModel.isLoading ? .secondary : .accentColor)
                        }
                        .disabled(viewModel.isLoading || viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select or start a new chat")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Button("New Chat") {
                        viewModel.newConversation()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading) {
                Text(message.content)
                    .padding()
                    .background(message.role == .user ? Color.accentColor : Color.secondary.opacity(0.1))
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 600, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

#Preview {
    ContentView()
}
