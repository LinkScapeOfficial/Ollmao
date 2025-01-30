//
//  ContentView.swift
//  Ollmao
//
//  Created by Zigao Wang on 1/28/25.
//

import SwiftUI
import MarkdownUI

struct ContentView: View {
    @StateObject private var conversationManager = ConversationManager()
    @StateObject private var viewModel: ChatViewModel
    
    init() {
        let manager = ConversationManager()
        _conversationManager = StateObject(wrappedValue: manager)
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversationManager: manager))
    }
    
    var body: some View {
        NavigationSplitView {
            SidebarView(
                conversations: viewModel.conversations,
                selectedId: $viewModel.selectedConversationId,
                selectedModel: $viewModel.selectedModel,
                availableModels: viewModel.availableModels,
                onNewChat: { viewModel.newConversation() },
                onDelete: { viewModel.deleteConversation($0) }
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
    let onDelete: (UUID) -> Void
    
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
                            onDelete: { onDelete(conversation.id) }
                        ) {
                            selectedId = conversation.id
                        }
                        Divider()
                    }
                }
            }
            
            Divider()
            
            // Model selector
            Picker("Model", selection: $selectedModel) {
                ForEach(availableModels, id: \.self) { model in
                    Text(model).tag(model)
                }
            }
            .pickerStyle(.menu)
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}

struct ConversationButton: View {
    let conversation: Conversation
    let isSelected: Bool
    let onDelete: () -> Void
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "message")
                    .foregroundColor(.secondary)
                Text(conversation.title)
                    .lineLimit(1)
                Spacer()
                
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
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
                        MessageView(message: .init(role: .assistant, content: viewModel.currentStreamContent))
                            .id("streaming")
                    } else if viewModel.isLoading {
                        HStack {
                            Image("Ollmao")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .clipShape(Circle())
                            Text("Waiting for assistant...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
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
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Select or create a conversation")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        HStack(alignment: .top) {
            Image("Ollmao")
                .resizable()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
            
            ProgressView()
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
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
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
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
                    ThinkingStreamView(content: message.content)
                } else {
                    MarkdownView(content: message.content)
                }
            }
        }
        .padding()
        .background(message.role == .user ? Color.gray.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

struct ThinkingStreamView: View {
    let content: String
    let isStreaming: Bool
    @State private var brainScale: CGFloat = 1.0
    @State private var isExpanded: Bool = true
    
    init(content: String, isStreaming: Bool = false) {
        self.content = content
        self.isStreaming = isStreaming
        _isExpanded = State(initialValue: isStreaming)
    }
    
    var body: some View {
        let thinkingContent = extractThinkingContent(from: content)
        
        VStack(alignment: .leading, spacing: 12) {
            // Thinking process section
            VStack(alignment: .leading, spacing: 8) {
                Button(action: { withAnimation { isExpanded.toggle() } }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .scaleEffect(brainScale)
                        Text("Thinking Process")
                            .foregroundColor(.purple)
                        Spacer()
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
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
                
                if isExpanded {
                    Group {
                        if thinkingContent.isEmpty {
                            Text("No thinking process")
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        } else {
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
                    }
                    .transition(AnyTransition.move(edge: .top).combined(with: .opacity))
                }
            }
            
            // Final answer section
            if let finalContent = extractFinalContent(from: content), !finalContent.isEmpty {
                MarkdownView(content: finalContent)
            }
        }
        .onChange(of: isStreaming) { _, newValue in
            withAnimation {
                isExpanded = newValue
            }
        }
    }
    
    private func extractThinkingContent(from content: String) -> String {
        guard let startRange = content.range(of: "<think>") else { return "" }
        
        let afterStartTag = content[startRange.upperBound...]
        if let endRange = afterStartTag.range(of: "</think>") {
            let thinking = String(afterStartTag[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            return thinking.isEmpty ? "" : thinking
        }
        
        let thinking = String(afterStartTag).trimmingCharacters(in: .whitespacesAndNewlines)
        return thinking.isEmpty ? "" : thinking
    }
    
    private func extractFinalContent(from content: String) -> String? {
        guard let endRange = content.range(of: "</think>") else { return nil }
        return String(content[endRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct MarkdownView: View {
    let content: String
    
    var body: some View {
        Markdown(content)
            .textSelection(.enabled)
            .applyCodeBlockStyle()
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension View {
    func applyCodeBlockStyle() -> some View {
        markdownBlockStyle(\.codeBlock) { configuration in
            VStack(alignment: .leading, spacing: 0) {
                // Language label if available
                if let language = configuration.language {
                    Text(language)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                
                // Code content
                ScrollView(.horizontal, showsIndicators: false) {
                    configuration.label
                        .font(.system(.body, design: .monospaced))
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .textBackgroundColor))
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = configuration.content
                    #else
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(configuration.content, forType: .string)
                    #endif
                } label: {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            }
            .padding(.vertical, 8)  // Add vertical margin
        }
    }
    
    func applyHeadingStyles() -> some View {
        self
            .markdownBlockStyle(\.heading1) { config in
                config.label
                    .foregroundColor(.primary)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.vertical, 8)
            }
            .markdownBlockStyle(\.heading2) { config in
                config.label
                    .foregroundColor(.primary)
                    .font(.system(size: 24, weight: .bold))
                    .padding(.vertical, 6)
            }
            .markdownBlockStyle(\.heading3) { config in
                config.label
                    .foregroundColor(.primary)
                    .font(.system(size: 20, weight: .bold))
                    .padding(.vertical, 4)
            }
    }
    
    func applyParagraphStyle() -> some View {
        markdownBlockStyle(\.paragraph) { config in
            config.label
                .foregroundColor(.primary)
                .font(.system(size: 16))
                .lineSpacing(4)
                .padding(.vertical, 2)
        }
    }
}

#Preview {
    ContentView()
}
