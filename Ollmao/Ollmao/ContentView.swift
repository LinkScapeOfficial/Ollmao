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
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(conversation.messages) { message in
                        MessageView(message: message)
                            .id(message.id)
                    }
                    
                    if !viewModel.currentStreamContent.isEmpty {
                        StreamingMessageView(content: viewModel.currentStreamContent)
                    } else if viewModel.isLoading {
                        TypingIndicator()
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            
            inputArea
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
            if message.role == .user {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                    }
            } else {
                Image("Ollmao")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.role == .user ? "You" : "Assistant")
                        .font(.headline)
                    Spacer()
                    Button {
                        #if os(iOS)
                        UIPasteboard.general.string = message.content
                        #else
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content, forType: .string)
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if message.content.contains("<think>") {
                    ThinkingView(content: message.content)
                } else {
                    Markdown(message.content)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(message.role == .user ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

struct ThinkingView: View {
    let content: String
    @State private var isThinkingExpanded = true
    @State private var brainScale: CGFloat = 1.0
    
    var body: some View {
        let thinkingContent = extractThinkingContent(from: content)
        if !thinkingContent.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    withAnimation(.spring()) {
                        isThinkingExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .scaleEffect(brainScale)
                        Text("Thinking Process")
                            .foregroundColor(.purple)
                        Spacer()
                        Image(systemName: isThinkingExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.purple)
                    }
                    .padding(8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                        brainScale = 1.1
                    }
                }
                
                if isThinkingExpanded {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(thinkingContent)
                            .textSelection(.enabled)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                            .overlay(
                                Rectangle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 4)
                                    .padding(.vertical, 4),
                                alignment: .leading
                            )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Final answer with markdown
                Markdown(extractFinalAnswer(from: content))
                    .textSelection(.enabled)
                    .padding(.top, 8)
            }
        } else {
            Markdown(content)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func extractThinkingContent(from content: String) -> String {
        if let start = content.range(of: "<think>")?.upperBound,
           let end = content.range(of: "</think>")?.lowerBound {
            let thinking = String(content[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
            if thinking.first == "\n" {
                return String(thinking.dropFirst())
            }
            return thinking
        }
        return ""
    }
    
    private func extractFinalAnswer(from content: String) -> String {
        if let end = content.range(of: "</think>")?.upperBound {
            return String(content[end...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return content
    }
}

struct ThinkingStreamView: View {
    let content: String
    @State private var brainScale: CGFloat = 1.0
    
    var body: some View {
        let cleanContent = content.replacingOccurrences(of: "<think>", with: "")
            .replacingOccurrences(of: "</think>", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !cleanContent.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                        .scaleEffect(brainScale)
                    Text("Thinking Process")
                        .foregroundColor(.purple)
                }
                .padding(8)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever()) {
                        brainScale = 1.1
                    }
                }
                
                let displayContent = cleanContent.first == "\n" ? String(cleanContent.dropFirst()) : cleanContent
                Text(displayContent)
                    .textSelection(.enabled)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        Rectangle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 4)
                            .padding(.vertical, 4),
                        alignment: .leading
                    )
            }
        } else {
            Markdown(content)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct StreamingMessageView: View {
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Ollmao")
                .resizable()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Assistant")
                        .font(.headline)
                    Spacer()
                    Button {
                        #if os(iOS)
                        UIPasteboard.general.string = content
                        #else
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(content, forType: .string)
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if content.contains("<think>") {
                    ThinkingStreamView(content: content)
                } else {
                    Markdown(content)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding()
        .background(Color.clear)
        .cornerRadius(8)
    }
}

struct TypingIndicator: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("Ollmao")
                .resizable()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            
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
