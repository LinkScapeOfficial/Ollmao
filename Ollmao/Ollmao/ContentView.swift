//
//  ContentView.swift
//  Ollmao
//
//  Created by Zigao Wang on 1/28/25.
//

import SwiftUI
import MarkdownUI

struct ContentView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                conversations: viewModel.conversations,
                selectedId: $viewModel.selectedConversationId,
                selectedModel: $viewModel.selectedModel,
                availableModels: viewModel.availableModels,
                onNewChat: { viewModel.newConversation() }
            )
            .frame(minWidth: 300)
        } detail: {
            if let conversation = viewModel.selectedConversation {
                ChatView(conversation: conversation, viewModel: viewModel)
            } else {
                EmptyStateView()
            }
        }
    }
}

struct SidebarView: View {
    let conversations: [Conversation]
    @Binding var selectedId: UUID?
    @Binding var selectedModel: String
    let availableModels: [String]
    let onNewChat: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // New Chat Button
            Button(action: onNewChat) {
                HStack {
                    Image(systemName: "plus")
                    Text("New Chat")
                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Conversations List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(conversations) { conversation in
                        ConversationButton(
                            conversation: conversation,
                            isSelected: selectedId == conversation.id,
                            action: { selectedId = conversation.id }
                        )
                        Divider()
                    }
                }
            }
        }
        .background(Color.gray.opacity(0.1))
    }
}

struct ConversationButton: View {
    let conversation: Conversation
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "message")
                    .foregroundColor(.secondary)
                Text(conversation.title)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(isSelected ? Color.gray.opacity(0.2) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

struct ChatView: View {
    let conversation: Conversation
    @ObservedObject var viewModel: ChatViewModel
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputArea
        }
    }
    
    private var messageList: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                ForEach(conversation.messages) { message in
                    MessageView(message: message)
                        .id(message.id)
                }
                
                if viewModel.isLoading {
                    TypingIndicator()
                }
                
                if !viewModel.currentStreamContent.isEmpty {
                    StreamingMessageView(content: viewModel.currentStreamContent)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 24)
        }
    }
    
    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Model selector above input
            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(viewModel.availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Send a message...", text: $viewModel.inputMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Task {
                                await viewModel.sendMessage()
                            }
                        }
                    }
                
                sendButton
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
    
    private var sendButton: some View {
        Button {
            Task {
                await viewModel.sendMessage()
            }
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 32))
                .symbolRenderingMode(.hierarchical)
                .foregroundColor(viewModel.inputMessage.isEmpty ? .secondary : .accentColor)
        }
        .disabled(viewModel.isLoading || viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .keyboardShortcut(.return, modifiers: [])
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar
            Circle()
                .fill(message.role == .user ? Color.blue : Color.green)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: message.role == .user ? "person.fill" : "brain")
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(message.role == .user ? "You" : "Assistant")
                    .font(.headline)
                Markdown(message.content)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding()
        .background(message.role == .user ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

struct StreamingMessageView: View {
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.green)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "brain")
                        .foregroundColor(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Assistant")
                    .font(.headline)
                Markdown(content)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.clear)
        .cornerRadius(8)
    }
}

struct TypingIndicator: View {
    var body: some View {
        HStack {
            Circle()
                .fill(Color.green)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: "brain")
                        .foregroundColor(.white)
                }
            
            Text("Assistant is typing...")
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding()
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            Text("Select a conversation or start a new chat")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .lineLimit(1)
                .foregroundColor(.primary)
            Text(conversation.model)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct LoadingView: View {
    var body: some View {
        HStack(alignment: .top) {
            Image("Ollmao")
                .resizable()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .padding(.top, 4)
            
            TypingIndicator()
                .padding()
            
            Spacer()
        }
        .padding()
    }
}

struct StreamingView: View {
    let content: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image("Ollmao")
                .resizable()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
                .padding(.top, 4)
            
            VStack(alignment: .leading) {
                Button(action: {
                    #if os(iOS)
                    UIPasteboard.general.string = content
                    #else
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    #endif
                }) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
                Markdown(content)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 16) {
                if message.role == .assistant {
                    Image("Ollmao")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    if message.role == .assistant {
                        Button(action: {
                            #if os(iOS)
                            UIPasteboard.general.string = message.content
                            #else
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.content, forType: .string)
                            #endif
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Markdown(message.content)
                        .textSelection(.enabled)
                        .markdownTheme(.gitHub)
                        .foregroundColor(message.role == .user ? .white : .primary)
                }
            }
            
            Text(message.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(message.role == .user ? Color.accentColor : Color.clear)
        .cornerRadius(8)
    }
}

struct ErrorView: View {
    let errorMessage: String?
    
    var body: some View {
        if let errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .foregroundColor(.red)
                .padding()
        }
    }
}

struct MessageInputRow: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState var isInputFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Message...", text: $viewModel.inputMessage, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
                .focused($isInputFocused)
            
            SendButton(viewModel: viewModel)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 16)
    }
}

struct SendButton: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        Button {
            Task {
                await viewModel.sendMessage()
            }
        } label: {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(viewModel.inputMessage.isEmpty ? .secondary : .accentColor)
        }
        .disabled(viewModel.isLoading || viewModel.inputMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .keyboardShortcut(.return, modifiers: [])
    }
}

struct LoadingContent: View {
    @ObservedObject var viewModel: ChatViewModel
    
    var body: some View {
        if !viewModel.isStreaming {
            LoadingView()
        } else if !viewModel.currentStreamContent.isEmpty {
            StreamingView(content: viewModel.currentStreamContent)
        }
    }
}

struct ChatInputView: View {
    @ObservedObject var viewModel: ChatViewModel
    @FocusState var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            ErrorView(errorMessage: viewModel.errorMessage)
            MessageInputRow(viewModel: viewModel, isInputFocused: _isInputFocused)
        }
    }
}

#Preview {
    ContentView()
}
