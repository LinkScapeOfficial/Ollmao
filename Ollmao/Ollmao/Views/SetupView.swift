import SwiftUI

struct SetupView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ChatViewModel
    @State private var currentStep = 0
    @State private var previousStep = 0
    @State private var systemRAM: Double = 0
    @State private var selectedModels: Set<String> = []
    @State private var showAdvancedSelection = false

    private let ollamaDownloadUrl = "https://ollama.com/download/Ollama-darwin.zip"

    private var modelCommands: String {
        selectedModels.map { "ollama pull \($0)" }.joined(separator: " && ")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                Group {
                    switch currentStep {
                    case 0:
                        welcomeView
                            .transition(currentStep > previousStep ?
                                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                                .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    case 1:
                        installOllamaView
                            .transition(currentStep > previousStep ?
                                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                                .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    case 2:
                        modelSelectionView
                            .transition(currentStep > previousStep ?
                                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                                .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    case 3:
                        installCommandsView
                            .transition(currentStep > previousStep ?
                                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                                .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    default:
                        completionView
                            .transition(currentStep > previousStep ?
                                .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)) :
                                .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 70)
            }

            VStack(spacing: 0) {
                Divider()
                HStack {
                    if currentStep > 0 {
                        Button("← Back") {
                            previousStep = currentStep
                            withAnimation(.easeInOut) {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Skip Setup") {
                        viewModel.completeSetup()
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)

                    Spacer()

                    if currentStep < 4 {
                        Button {
                            previousStep = currentStep
                            withAnimation(.easeInOut) {
                                currentStep += 1
                            }
                        } label: {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            viewModel.completeSetup()
                            dismiss()
                        } label: {
                            Text("Start Using Ollmao")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(.background)
            }
        }
        .frame(width: 800, height: 600)
        .onAppear {
            getSystemInfo()
        }
    }

    private var welcomeView: some View {
        VStack(spacing: 24) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)

            Text("Welcome to Ollmao")
                .font(.system(size: 32, weight: .bold))

            Text("Your AI coding assistant powered by Ollama")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            HStack(spacing: 16) {
                featureBox(
                    icon: "lock.shield.fill",
                    title: "100% Private",
                    description: "Local processing"
                )

                featureBox(
                    icon: "banknote.fill",
                    title: "Free to Use",
                    description: "No API keys"
                )
            }

            HStack(spacing: 16) {
                featureBox(
                    icon: "cpu.fill",
                    title: "Powerful Models",
                    description: "Latest AI models"
                )

                featureBox(
                    icon: "bolt.fill",
                    title: "Fast Response",
                    description: "No latency"
                )
            }
        }
        .padding(40)
    }

    private func featureBox(icon: String, title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary)
        .cornerRadius(12)
    }

    private var installOllamaView: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Install Ollama Engine")
                    .font(.system(size: 28, weight: .bold))
                
                HStack(spacing: 40) {
                    appCard(
                        image: "Logo",
                        title: "Ollmao",
                        pronunciation: "OH-luh-MAO",
                        description: "The app you're using"
                    )
                    
                    Text("needs")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    appCard(
                        image: "Ollama",
                        title: "Ollama",
                        pronunciation: "oh-LAH-ma",
                        description: "The AI engine"
                    )
                }
                
                VStack(spacing: 20) {
                    Link(destination: URL(string: ollamaDownloadUrl)!) {
                        HStack {
                            Text("Download Ollama")
                                .font(.headline)
                            Image(systemName: "arrow.down.circle.fill")
                        }
                        .padding()
                        .frame(width: 200)
                        .background(.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Text("Required to run AI models locally")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(40)
        }
    }

    private func appCard(image: String, title: String, pronunciation: String, description: String) -> some View {
        VStack(spacing: 16) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)

            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                Text("(\(pronunciation))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.quaternary)
        .cornerRadius(16)
    }

    private var modelSelectionView: some View {
        ScrollView {
            VStack(spacing: 40) {
                Text("Choose Your Model")
                    .font(.system(size: 28, weight: .bold))

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Understanding Models & RAM")
                            .font(.headline)

                        Group {
                            modelInfoRow(
                                icon: "cpu",
                                title: "Model Size & RAM",
                                description: "Larger models (7B, 13B) need more RAM but are smarter. Smaller models (1.5B, 3B) use less RAM but are still capable."
                            )

                            modelInfoRow(
                                icon: "memorychip",
                                title: "Your System",
                                description: "Your Mac has \(Int(systemRAM))GB RAM. We recommend using models that need less than 80% of your total RAM."
                            )

                            modelInfoRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Multiple Models",
                                description: "Start with our recommended model below. Show advanced options to download more models for different tasks!"
                            )
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.quaternary)
                    .cornerRadius(12)

                    recommendedModelCard

                    Button {
                        withAnimation {
                            showAdvancedSelection.toggle()
                        }
                    } label: {
                        HStack {
                            Text(showAdvancedSelection ? "Hide Advanced Options" : "Show More Models")
                                .font(.headline)
                            Image(systemName: showAdvancedSelection ? "chevron.up" : "chevron.down")
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(.quaternary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    if showAdvancedSelection {
                        VStack(spacing: 20) {
                            ForEach(modelFamilies, id: \.name) { family in
                                ModelFamilyCard(
                                    family: family,
                                    systemRAM: systemRAM,
                                    selectedModels: $selectedModels
                                )
                            }
                        }
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
    }

    private func modelInfoRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var completionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.system(size: 32, weight: .bold))

            Text("Start chatting with your AI assistant")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .padding(40)
    }

    private var installCommandsView: some View {
        VStack(spacing: 32) {
            Text("Install Selected Models")
                .font(.system(size: 28, weight: .bold))

            if !selectedModels.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Run this command in Terminal:")
                        .font(.headline)

                    HStack {
                        Text(modelCommands)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .background(.background)
                            .cornerRadius(8)

                        Button {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(modelCommands, forType: .string)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .padding(8)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                    } label: {
                        HStack {
                            Image(systemName: "terminal")
                            Text("Open Terminal")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(.background)
                .cornerRadius(12)
            }
        }
        .padding(40)
    }

    private let modelFamilies = [
        ModelFamily(
            name: "DeepSeek-r1",
            description: "DeepSeek's first-generation reasoning models with comparable performance to OpenAI-o1",
            sizes: [
                ModelSize(name: "1.5b", ramGB: 8),
                ModelSize(name: "7b", ramGB: 16),
                ModelSize(name: "8b", ramGB: 16),
                ModelSize(name: "14b", ramGB: 24),
                ModelSize(name: "32b", ramGB: 48),
                ModelSize(name: "70b", ramGB: 100),
                ModelSize(name: "671b", ramGB: 200)
            ]
        ),
        ModelFamily(
            name: "Llama3.1",
            description: "Meta's state-of-the-art model with strong general capabilities",
            sizes: [
                ModelSize(name: "8b", ramGB: 16),
                ModelSize(name: "70b", ramGB: 100),
                ModelSize(name: "405b", ramGB: 200)
            ]
        ),
        ModelFamily(
            name: "Qwen2.5",
            description: "Alibaba's latest model with 128K context and strong multilingual support",
            sizes: [
                ModelSize(name: "0.5b", ramGB: 4),
                ModelSize(name: "1.5b", ramGB: 8),
                ModelSize(name: "3b", ramGB: 12),
                ModelSize(name: "7b", ramGB: 16),
                ModelSize(name: "14b", ramGB: 24),
                ModelSize(name: "32b", ramGB: 48),
                ModelSize(name: "72b", ramGB: 100)
            ]
        )
    ]

    private var recommendedModelCard: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommended Model")
                        .font(.headline)
                    Text("Best balance of performance and speed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
            }

            let recommendedModel = systemRAM >= 16 ? "qwen2.5:7b" : "qwen2.5:1.5b"
            let modelSize = systemRAM >= 16 ? "7B" : "1.5B"
            let isSelected = selectedModels.contains(recommendedModel)

            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Qwen 2.5 \(modelSize)")
                            .font(.headline)
                        Text("Alibaba's latest model")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        if isSelected {
                            selectedModels.remove(recommendedModel)
                        } else {
                            selectedModels.insert(recommendedModel)
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            Text(isSelected ? "Selected" : "Select")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.accentColor : Color(nsColor: .quaternaryLabelColor))
                        .foregroundColor(isSelected ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    featureRow(icon: "sparkles", text: "Great for chat and coding")
                    featureRow(icon: "cpu", text: "Runs smoothly on your Mac")
                    featureRow(icon: "globe", text: "Multilingual support")
                }
            }
            .padding()
            .background(Color(nsColor: .quaternaryLabelColor))
            .cornerRadius(12)
        }
        .padding()
        .background(Color(nsColor: .quaternaryLabelColor))
        .cornerRadius(16)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func getSystemInfo() {
        let process = Process()
        process.launchPath = "/usr/sbin/sysctl"
        process.arguments = ["hw.memsize"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let components = output.components(separatedBy: " ")
                if let last = components.last,
                   let bytes = Double(last.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    systemRAM = bytes / 1024 / 1024 / 1024 // Convert to GB
                }
            }
        } catch {
            print("Error getting system info: \(error)")
            systemRAM = 16 // Default assumption
        }
    }
}

struct ModelFamily: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let sizes: [ModelSize]
}

struct ModelSize: Identifiable {
    let id = UUID()
    let name: String
    let ramGB: Double
}

struct ModelFamilyCard: View {
    let family: ModelFamily
    let systemRAM: Double
    @Binding var selectedModels: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(family.name)
                .font(.headline)
                .bold()

            Text(family.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Available Sizes:")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100, maximum: 150))
            ], spacing: 12) {
                ForEach(family.sizes, id: \.name) { size in
                    ModelSizeButton(
                        familyName: family.name,
                        size: size,
                        systemRAM: systemRAM,
                        selectedModels: $selectedModels
                    )
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .quaternaryLabelColor))
        .cornerRadius(12)
    }
}

struct ModelSizeButton: View {
    let familyName: String
    let size: ModelSize
    let systemRAM: Double
    @Binding var selectedModels: Set<String>

    var modelId: String {
        "\(familyName.lowercased()):\(size.name)"
    }

    var isSelected: Bool {
        selectedModels.contains(modelId)
    }

    var isCompatible: Bool {
        systemRAM >= Double(size.ramGB)
    }

    var body: some View {
        Button {
            if isSelected {
                selectedModels.remove(modelId)
            } else if isCompatible {
                selectedModels.insert(modelId)
            }
        } label: {
            VStack(spacing: 4) {
                Text(size.name)
                    .font(.headline)
                Text("\(Int(size.ramGB))GB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(!isCompatible)
    }

    private var backgroundColor: Color {
        if isSelected {
            return .accentColor
        } else if isCompatible {
            return Color(nsColor: .quaternaryLabelColor)
        } else {
            return Color(nsColor: .quaternaryLabelColor).opacity(0.5)
        }
    }

    private var foregroundColor: Color {
        if isSelected {
            return .white
        } else if isCompatible {
            return .primary
        } else {
            return .secondary
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(
                    x: bounds.minX + result.positions[index].x,
                    y: bounds.minY + result.positions[index].y
                ),
                proposal: ProposedViewSize(result.sizes[index])
            )
        }
    }

    struct FlowResult {
        var positions: [CGPoint]
        var sizes: [CGSize]
        var size: CGSize

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var positions: [CGPoint] = []
            var sizes: [CGSize] = []

            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            var rowMaxY: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                sizes.append(size)

                if x + size.width > maxWidth, !positions.isEmpty {
                    x = 0
                    y = rowMaxY + spacing
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                rowMaxY = y + rowHeight
                x += size.width + spacing
            }

            self.positions = positions
            self.sizes = sizes
            self.size = CGSize(width: maxWidth, height: rowMaxY)
        }
    }
}
